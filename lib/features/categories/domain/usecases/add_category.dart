import '../entities/category.dart';
import '../repositories/category_repository.dart';

class AddCategory {
  const AddCategory(this._repository);

  final CategoryRepository _repository;

  Future<Category> call(String name, {int? parentId}) =>
      _repository.addCategory(name, parentId: parentId);
}
