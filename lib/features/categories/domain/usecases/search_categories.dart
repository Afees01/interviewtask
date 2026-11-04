import '../entities/category_search_result.dart';
import '../repositories/category_repository.dart';

class SearchCategories {
  const SearchCategories(this._repository);

  final CategoryRepository _repository;

  Future<List<CategorySearchResult>> call(String query) {
    return _repository.searchCategories(query);
  }
}
