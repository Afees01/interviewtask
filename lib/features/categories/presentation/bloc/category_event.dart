import 'package:equatable/equatable.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

final class LoadCategories extends CategoryEvent {
  const LoadCategories({this.rootsOnly = false});

  final bool rootsOnly;

  @override
  List<Object?> get props => [rootsOnly];
}

final class ClearCategories extends CategoryEvent {
  const ClearCategories();
}

final class SearchCategories extends CategoryEvent {
  const SearchCategories(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class ClearCategorySearch extends CategoryEvent {
  const ClearCategorySearch();
}

final class AddCategory extends CategoryEvent {
  const AddCategory({required this.name, this.parentId});

  final String name;
  final int? parentId;

  @override
  List<Object?> get props => [name, parentId];
}

final class UpdateCategory extends CategoryEvent {
  const UpdateCategory({
    required this.id,
    required this.name,
    required this.parentId,
  });

  final int id;
  final String name;
  final int? parentId;

  @override
  List<Object?> get props => [id, name, parentId];
}

final class DeleteCategory extends CategoryEvent {
  const DeleteCategory(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

final class LoadChildren extends CategoryEvent {
  const LoadChildren(this.parentId);

  final int parentId;

  @override
  List<Object?> get props => [parentId];
}
