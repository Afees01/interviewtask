import 'package:equatable/equatable.dart';

import 'category.dart';

class CategorySearchResult extends Equatable {
  const CategorySearchResult({
    required this.category,
    required this.ancestors,
    required this.directChildren,
    required this.descendants,
    required this.hierarchyPath,
    required this.hierarchy,
  });

  final Category category;
  final List<Category> ancestors;
  final List<Category> directChildren;
  final List<Category> descendants;
  final List<Category> hierarchyPath;
  final Category hierarchy;

  @override
  List<Object?> get props => [
        category,
        ancestors,
        directChildren,
        descendants,
        hierarchyPath,
        hierarchy,
      ];
}
