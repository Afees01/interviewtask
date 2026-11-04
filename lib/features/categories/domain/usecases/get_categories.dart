import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategories {
  const GetCategories(this._repository);

  final CategoryRepository _repository;

  Future<List<Category>> call({bool rootsOnly = false}) {
    return rootsOnly
        ? _repository.getRootCategories()
        : _repository.getCategories();
  }
}
