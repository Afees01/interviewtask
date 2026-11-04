import '../entities/category.dart';
import '../entities/category_search_result.dart';

abstract interface class CategoryRepository {
  Future<Category> addCategory(String name, {int? parentId});

  Future<Category> updateCategory({
    required int id,
    required String name,
    required int? parentId,
  });

  Future<void> deleteCategory(int id);

  Future<List<Category>> getCategories();

  Future<List<Category>> getRootCategories();

  Future<List<Category>> getChildren(int parentId);

  Future<Category?> getCategoryById(int id);

  Future<List<CategorySearchResult>> searchCategories(String query);
}
