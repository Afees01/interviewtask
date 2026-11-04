import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_factory_initializer.dart' as factory_initializer;

class AppDatabase {
  const AppDatabase();

  static const databaseName = 'category_manager.db';
  static const databaseVersion = 2;
  static const categoriesTable = 'categories';

  Future<Database> open({String? databasePath}) async {
    factory_initializer.initializeDatabaseFactory();

    final resolvedPath = databasePath ??
        (kIsWeb
            ? databaseName
            : path.join(await getDatabasesPath(), databaseName));

    return openDatabase(
      resolvedPath,
      version: databaseVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 1) {
          await _createSchema(database, newVersion);
        } else if (oldVersion < 2) {
          await _migrateToUserScopedCategories(database);
        }
      },
    );
  }

  Future<void> _migrateToUserScopedCategories(Database database) async {
    await database.execute(
      'ALTER TABLE $categoriesTable RENAME TO legacy_categories',
    );
    await database.execute('DROP INDEX IF EXISTS categories_parent_id_index');
    await database.execute('DROP INDEX IF EXISTS categories_root_name_unique');
    await database.execute(
      'DROP INDEX IF EXISTS categories_parent_name_unique',
    );
    await _createSchema(database, databaseVersion);
  }

  Future<void> _createSchema(Database database, int version) async {
    await database.execute('''
      CREATE TABLE $categoriesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER NULL,
        created_at TEXT NOT NULL,
        user_id INTEGER NOT NULL,
        UNIQUE (id, user_id),
        FOREIGN KEY (parent_id, user_id)
          REFERENCES $categoriesTable(id, user_id)
          ON DELETE CASCADE
      )
    ''');
    await database.execute(
      'CREATE INDEX categories_user_parent_index '
      'ON $categoriesTable(user_id, parent_id)',
    );
    await database.execute(
      'CREATE UNIQUE INDEX categories_root_name_unique '
      'ON $categoriesTable(user_id, name) WHERE parent_id IS NULL',
    );
    await database.execute(
      'CREATE UNIQUE INDEX categories_parent_name_unique '
      'ON $categoriesTable(user_id, parent_id, name) '
      'WHERE parent_id IS NOT NULL',
    );
  }
}
