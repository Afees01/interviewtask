import '../repositories/category_repository.dart';

class DeleteCategory {
  const DeleteCategory(this._repository);

  final CategoryRepository _repository;

  Future<void> call(int id) => _repository.deleteCategory(id);
}
