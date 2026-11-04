import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:interviewtask/core/database/app_database.dart';
import 'package:interviewtask/features/categories/data/datasources/category_local_data_source.dart';
import 'package:interviewtask/features/categories/data/models/category_model.dart';
import 'package:interviewtask/features/categories/data/repositories/category_repository_impl.dart';
import 'package:interviewtask/features/categories/domain/exceptions/category_exception.dart';
import 'package:interviewtask/features/categories/domain/repositories/category_repository.dart';
import 'package:interviewtask/core/session/user_session.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory temporaryDirectory;
  late Database database;
  late CategoryRepository repository;
  late SharedPreferences preferences;
  late UserSession userSession;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      UserSession.authenticatedUserIdKey: 1,
    });
    preferences = await SharedPreferences.getInstance();
    userSession = UserSession(preferences);
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'category-manager-test-',
    );
    database = await const AppDatabase().open(
      databasePath: path.join(temporaryDirectory.path, 'category_manager.db'),
    );
    repository = CategoryRepositoryImpl(
      CategoryLocalDataSourceImpl(database, userSession),
    );
  });

  tearDown(() async {
    await database.close();
    await temporaryDirectory.delete(recursive: true);
  });

  test('initializes versioned schema with foreign keys and indexes', () async {
    final version = await database.getVersion();
    final foreignKeys = await database.rawQuery('PRAGMA foreign_keys');
    final table = await database.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'categories'",
    );
    final indexes = await database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'index' AND tbl_name = 'categories'",
    );

    expect(version, AppDatabase.databaseVersion);
    expect(foreignKeys.single['foreign_keys'], 1);
    expect(table.single['sql'], contains('created_at TEXT NOT NULL'));
    expect(table.single['sql'], contains('user_id INTEGER NOT NULL'));
    expect(table.single['sql'], contains('ON DELETE CASCADE'));
    expect(
      indexes.map((row) => row['name']),
      containsAll([
        'categories_user_parent_index',
        'categories_root_name_unique',
        'categories_parent_name_unique',
      ]),
    );
  });

  test('adds root and nested categories and retrieves relationships', () async {
    final root = await repository.addCategory('  Books  ');
    final child = await repository.addCategory('Fiction', parentId: root.id);
    final grandchild = await repository.addCategory(
      'Mystery',
      parentId: child.id,
    );

    expect(root.name, 'Books');
    expect(root.parentId, isNull);
    expect((await repository.getCategories()).length, 3);
    expect((await repository.getRootCategories()).map((item) => item.id),
        [root.id]);
    expect((await repository.getChildren(root.id!)).single.id, child.id);
    expect((await repository.getChildren(child.id!)).single.id, grandchild.id);
    expect((await repository.getCategoryById(grandchild.id!))?.name, 'Mystery');
  });

  test('rejects duplicate names under the same parent including root',
      () async {
    final firstRoot = await repository.addCategory('Shared');
    final secondRoot = await repository.addCategory('Other');

    await expectLater(
      repository.addCategory('Shared'),
      throwsA(isA<DuplicateCategoryException>()),
    );

    await repository.addCategory('Same child', parentId: firstRoot.id);
    await expectLater(
      repository.addCategory('Same child', parentId: firstRoot.id),
      throwsA(isA<DuplicateCategoryException>()),
    );
    await expectLater(
      repository.addCategory('Same child', parentId: secondRoot.id),
      completes,
    );
  });

  test('rejects empty names and missing parents', () async {
    await expectLater(
      repository.addCategory('  '),
      throwsA(isA<InvalidCategoryNameException>()),
    );
    await expectLater(
      repository.addCategory('Orphan', parentId: 9999),
      throwsA(isA<ParentCategoryNotFoundException>()),
    );
  });

  test('updates category fields and prevents circular reparenting', () async {
    final root = await repository.addCategory('Root');
    final child = await repository.addCategory('Child', parentId: root.id);
    final otherRoot = await repository.addCategory('Other');

    final moved = await repository.updateCategory(
      id: child.id!,
      name: 'Moved child',
      parentId: otherRoot.id,
    );
    expect(moved.name, 'Moved child');
    expect(moved.parentId, otherRoot.id);

    await expectLater(
      repository.updateCategory(
        id: otherRoot.id!,
        name: 'Other',
        parentId: child.id,
      ),
      throwsA(isA<CircularCategoryException>()),
    );
    await expectLater(
      repository.updateCategory(
        id: 9999,
        name: 'Missing',
        parentId: null,
      ),
      throwsA(isA<CategoryNotFoundException>()),
    );
  });

  test('deletes a category and all descendants in a transaction', () async {
    final root = await repository.addCategory('Root');
    final child = await repository.addCategory('Child', parentId: root.id);
    await repository.addCategory('Grandchild', parentId: child.id);

    await repository.deleteCategory(root.id!);

    expect(await repository.getCategories(), isEmpty);
    await expectLater(
      repository.deleteCategory(root.id!),
      throwsA(isA<CategoryNotFoundException>()),
    );
  });

  test('persists categories when the database is reopened', () async {
    final stored = await repository.addCategory('Persistent');
    final databasePath = path.join(
      temporaryDirectory.path,
      AppDatabase.databaseName,
    );
    await database.close();
    database = await const AppDatabase().open(databasePath: databasePath);
    repository = CategoryRepositoryImpl(
      CategoryLocalDataSourceImpl(database, userSession),
    );

    expect((await repository.getCategoryById(stored.id!))?.name, 'Persistent');
  });

  test(
      'searches root and nested categories with case-insensitive partial and '
      'exact matching', () async {
    final electronics = await repository.addCategory('Electronics');
    final mobile = await repository.addCategory(
      'Mobile',
      parentId: electronics.id,
    );
    final android = await repository.addCategory(
      'Android',
      parentId: mobile.id,
    );
    final samsung = await repository.addCategory(
      'Samsung',
      parentId: android.id,
    );
    final galaxy = await repository.addCategory(
      'Galaxy',
      parentId: samsung.id,
    );
    final series = await repository.addCategory(
      'S-Series',
      parentId: galaxy.id,
    );
    final ultra = await repository.addCategory(
      'Ultra',
      parentId: series.id,
    );
    await repository.addCategory('Samsung devices');

    final multipleMatches = await repository.searchCategories('sAmSuNg');
    expect(multipleMatches.map((result) => result.category.name),
        ['Samsung', 'Samsung devices']);

    final result = multipleMatches.first;
    expect(
      result.ancestors.map((category) => category.name),
      ['Electronics', 'Mobile', 'Android'],
    );
    expect(result.directChildren.map((category) => category.name), ['Galaxy']);
    expect(
      result.descendants.map((category) => category.name),
      ['Galaxy', 'S-Series', 'Ultra'],
    );
    expect(
      result.hierarchyPath.map((category) => category.name),
      ['Electronics', 'Mobile', 'Android', 'Samsung'],
    );
    expect(result.hierarchy.children.single.name, 'Mobile');
    expect(
      result.hierarchy.children.single.children.single.children.single.name,
      'Samsung',
    );
    expect(
      result.hierarchy.children.single.children.single.children.single.children
          .single.name,
      'Galaxy',
    );

    final deepMatch = await repository.searchCategories('lTrA');
    expect(deepMatch.single.category.id, ultra.id);
    expect(deepMatch.single.hierarchyPath, hasLength(7));

    final exact = await repository.searchCategories('Electronics');
    expect(exact.single.category.id, electronics.id);
    final partial = await repository.searchCategories('lect');
    expect(partial.single.category.id, electronics.id);
  });

  test('returns no results for empty and unmatched searches', () async {
    await repository.addCategory('Books');

    expect(await repository.searchCategories('  '), isEmpty);
    expect(await repository.searchCategories('nonexistent'), isEmpty);
  });

  test('converts category models between maps and nested JSON', () async {
    final root = CategoryModel(
      id: 1,
      name: 'Root',
      parentId: null,
      createdAt: DateTime.utc(2025),
      userId: 1,
      children: [
        CategoryModel(
          id: 2,
          name: 'Child',
          parentId: 1,
          createdAt: DateTime.utc(2025, 1, 2),
          userId: 1,
        ),
      ],
    );

    final restored = CategoryModel.fromJson(root.toJson());
    expect(restored, root);
    expect(
      CategoryModel.fromMap(root.toMap()).parentId,
      isNull,
    );
  });

  test('isolates category operations by the saved user ID', () async {
    final userOneRoot = await repository.addCategory('Electronics');
    final userOneChild =
        await repository.addCategory('Mobile', parentId: userOneRoot.id);

    await preferences.setInt(UserSession.authenticatedUserIdKey, 2);
    final userTwoRoot = await repository.addCategory('Electronics');
    final userTwoChild =
        await repository.addCategory('Laptop', parentId: userTwoRoot.id);

    expect(userOneRoot.userId, 1);
    expect(userTwoRoot.userId, 2);
    expect((await repository.getCategories()).map((item) => item.name),
        ['Electronics', 'Laptop']);
    expect((await repository.getChildren(userTwoRoot.id!)).single.id,
        userTwoChild.id);
    expect(await repository.getCategoryById(userOneChild.id!), isNull);
    await expectLater(
      repository.addCategory('Android', parentId: userOneChild.id),
      throwsA(isA<ParentCategoryNotFoundException>()),
    );
    await expectLater(
      repository.updateCategory(
        id: userOneChild.id!,
        name: 'Android',
        parentId: userTwoRoot.id,
      ),
      throwsA(isA<CategoryNotFoundException>()),
    );
    await expectLater(
      repository.deleteCategory(userOneChild.id!),
      throwsA(isA<CategoryNotFoundException>()),
    );
    expect(await repository.getCategoryById(userOneChild.id!), isNull);

    await preferences.remove(UserSession.authenticatedUserIdKey);
    await expectLater(
      repository.getCategories(),
      throwsA(isA<UnauthenticatedCategoryException>()),
    );
  });

  test('safely quarantines ownerless rows during version 1 migration',
      () async {
    final legacyPath = path.join(
      temporaryDirectory.path,
      'legacy_category_manager.db',
    );
    final legacyDatabase = await openDatabase(
      legacyPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            parent_id INTEGER NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (parent_id) REFERENCES categories(id)
              ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX categories_parent_id_index ON categories(parent_id)',
        );
        await db.execute(
          'CREATE UNIQUE INDEX categories_root_name_unique '
          'ON categories(name) WHERE parent_id IS NULL',
        );
        await db.execute(
          'CREATE UNIQUE INDEX categories_parent_name_unique '
          'ON categories(parent_id, name) WHERE parent_id IS NOT NULL',
        );
        await db.insert('categories', {
          'id': 42,
          'name': 'Legacy root',
          'parent_id': null,
          'created_at': DateTime.utc(2024).toIso8601String(),
        });
        await db.insert('categories', {
          'id': 43,
          'name': 'Legacy child',
          'parent_id': 42,
          'created_at': DateTime.utc(2024, 1, 2).toIso8601String(),
        });
      },
    );
    await legacyDatabase.close();

    await database.close();
    database = await const AppDatabase().open(databasePath: legacyPath);
    repository = CategoryRepositoryImpl(
      CategoryLocalDataSourceImpl(database, userSession),
    );

    final schema = await database.rawQuery('PRAGMA table_info(categories)');
    final migratedRows = await database.query('categories');
    final quarantinedRows = await database.query('legacy_categories');

    expect(await database.getVersion(), AppDatabase.databaseVersion);
    expect(
      schema.singleWhere((column) => column['name'] == 'user_id')['notnull'],
      1,
    );
    expect(migratedRows, isEmpty);
    expect(quarantinedRows.length, 2);
    expect(await repository.getCategories(), isEmpty);
    expect(
      quarantinedRows.map((row) => row['name']),
      containsAll(['Legacy root', 'Legacy child']),
    );
  });
}
