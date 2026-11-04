import '../../domain/entities/category.dart';
import '../../domain/entities/category_search_result.dart';
import '../../domain/exceptions/category_exception.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_data_source.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._localDataSource);

  final CategoryLocalDataSource _localDataSource;

  @override
  Future<Category> addCategory(String name, {int? parentId}) async {
    final normalizedName = _validateName(name);
    return _localDataSource.addCategory(
      name: normalizedName,
      parentId: parentId,
      createdAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<Category> updateCategory({
    required int id,
    required String name,
    required int? parentId,
  }) {
    final normalizedName = _validateName(name);
    return _localDataSource.updateCategory(
      id: id,
      name: normalizedName,
      parentId: parentId,
    );
  }

  @override
  Future<void> deleteCategory(int id) => _localDataSource.deleteCategory(id);

  @override
  Future<List<Category>> getCategories() => _localDataSource.getCategories();

  @override
  Future<List<Category>> getRootCategories() =>
      _localDataSource.getRootCategories();

  @override
  Future<List<Category>> getChildren(int parentId) =>
      _localDataSource.getChildren(parentId);

  @override
  Future<Category?> getCategoryById(int id) =>
      _localDataSource.getCategoryById(id);

  @override
  Future<List<CategorySearchResult>> searchCategories(String query) =>
      _localDataSource.searchCategories(query);

  String _validateName(String name) {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const InvalidCategoryNameException();
    }
    return normalizedName;
  }
}
