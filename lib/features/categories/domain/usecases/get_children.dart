import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetChildren {
  const GetChildren(this._repository);

  final CategoryRepository _repository;

  Future<List<Category>> call(int parentId) =>
      _repository.getChildren(parentId);
}
