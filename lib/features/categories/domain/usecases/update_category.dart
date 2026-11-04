import '../entities/category.dart';
import '../repositories/category_repository.dart';

class UpdateCategory {
  const UpdateCategory(this._repository);

  final CategoryRepository _repository;

  Future<Category> call({
    required int id,
    required String name,
    required int? parentId,
  }) {
    return _repository.updateCategory(
      id: id,
      name: name,
      parentId: parentId,
    );
  }
}
