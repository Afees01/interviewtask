import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/session/user_session.dart';
import '../../domain/entities/category_search_result.dart';
import '../../domain/exceptions/category_exception.dart';
import '../../domain/utils/category_hierarchy.dart';
import '../models/category_model.dart';

abstract interface class CategoryLocalDataSource {
  Future<CategoryModel> addCategory({
    required String name,
    required int? parentId,
    required DateTime createdAt,
  });

  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required int? parentId,
  });

  Future<void> deleteCategory(int id);

  Future<List<CategoryModel>> getCategories();

  Future<List<CategoryModel>> getRootCategories();

  Future<List<CategoryModel>> getChildren(int parentId);

  Future<CategoryModel?> getCategoryById(int id);

  Future<List<CategorySearchResult>> searchCategories(String query);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  const CategoryLocalDataSourceImpl(this._database, this._userSession);

  final Database _database;
  final UserSession _userSession;

  static const _table = AppDatabase.categoriesTable;
  static const _columns = [
    'id',
    'name',
    'parent_id',
    'created_at',
    'user_id',
  ];

  @override
  Future<CategoryModel> addCategory({
    required String name,
    required int? parentId,
    required DateTime createdAt,
  }) async {
    final userId = _currentUserId();
    try {
      return await _database.transaction((transaction) async {
        await _ensureParentExists(transaction, parentId, userId);
        final id = await transaction.insert(_table, {
          'name': name,
          'parent_id': parentId,
          'created_at': createdAt.toUtc().toIso8601String(),
          'user_id': userId,
        });
        final row = await transaction.query(
          _table,
          columns: _columns,
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
          limit: 1,
        );
        return CategoryModel.fromMap(row.single);
      });
    } on DatabaseException catch (error) {
      _mapConstraintError(error);
    }
  }

  @override
  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required int? parentId,
  }) async {
    final userId = _currentUserId();

    try {
      return await _database.transaction((transaction) async {
        final existing = await transaction.query(
          _table,
          columns: _columns,
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
          limit: 1,
        );
        if (existing.isEmpty) {
          throw const CategoryNotFoundException();
        }

        await _ensureParentExists(transaction, parentId, userId);
        await _ensureNoCycle(transaction, id, parentId, userId);
        await transaction.update(
          _table,
          {'name': name, 'parent_id': parentId},
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );
        final updated = await transaction.query(
          _table,
          columns: _columns,
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
          limit: 1,
        );
        return CategoryModel.fromMap(updated.single);
      });
    } on DatabaseException catch (error) {
      _mapConstraintError(error);
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    final userId = _currentUserId();
    await _database.transaction((transaction) async {
      final deleted = await transaction.delete(
        _table,
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
      if (deleted == 0) {
        throw const CategoryNotFoundException();
      }
    });
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final userId = _currentUserId();
    final rows = await _database.query(
      _table,
      columns: _columns,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at, id',
    );
    return rows.map(CategoryModel.fromMap).toList(growable: false);
  }

  @override
  Future<List<CategoryModel>> getRootCategories() async {
    final userId = _currentUserId();
    final rows = await _database.query(
      _table,
      columns: _columns,
      where: 'user_id = ? AND parent_id IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at, id',
    );
    return rows.map(CategoryModel.fromMap).toList(growable: false);
  }

  @override
  Future<List<CategoryModel>> getChildren(int parentId) async {
    final userId = _currentUserId();
    final rows = await _database.query(
      _table,
      columns: _columns,
      where: 'user_id = ? AND parent_id = ?',
      whereArgs: [userId, parentId],
      orderBy: 'created_at, id',
    );
    return rows.map(CategoryModel.fromMap).toList(growable: false);
  }

  @override
  Future<CategoryModel?> getCategoryById(int id) async {
    final userId = _currentUserId();
    final rows = await _database.query(
      _table,
      columns: _columns,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    return rows.isEmpty ? null : CategoryModel.fromMap(rows.single);
  }

  @override
  Future<List<CategorySearchResult>> searchCategories(String query) async {
    if (query.trim().isEmpty) {
      _currentUserId();
      return const [];
    }
    final userId = _currentUserId();
    final rows = await _database.query(
      _table,
      columns: _columns,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at, id',
    );
    final categories = rows.map(CategoryModel.fromMap).toList(growable: false);
    return CategoryHierarchy.search(categories, query);
  }

  Future<void> _ensureParentExists(
    DatabaseExecutor database,
    int? parentId,
    int userId,
  ) async {
    if (parentId == null) {
      return;
    }
    final rows = await database.query(
      _table,
      columns: ['id'],
      where: 'id = ? AND user_id = ?',
      whereArgs: [parentId, userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw const ParentCategoryNotFoundException();
    }
  }

  Future<void> _ensureNoCycle(
    DatabaseExecutor database,
    int categoryId,
    int? prospectiveParentId,
    int userId,
  ) async {
    var ancestorId = prospectiveParentId;
    while (ancestorId != null) {
      if (ancestorId == categoryId) {
        throw const CircularCategoryException();
      }
      final rows = await database.query(
        _table,
        columns: ['parent_id'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [ancestorId, userId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw const ParentCategoryNotFoundException();
      }
      ancestorId = rows.single['parent_id'] as int?;
    }
  }

  int _currentUserId() {
    final userId = _userSession.userId;
    if (userId == null || userId <= 0) {
      throw const UnauthenticatedCategoryException();
    }
    return userId;
  }

  Never _mapConstraintError(DatabaseException error) {
    final message = error.toString();
    if (message.contains('UNIQUE constraint failed')) {
      throw const DuplicateCategoryException();
    }
    if (message.contains('FOREIGN KEY constraint failed')) {
      throw const ParentCategoryNotFoundException();
    }
    throw error;
  }
}
