import '../entities/category.dart';
import '../entities/category_search_result.dart';

class CategoryHierarchy {
  const CategoryHierarchy._();

  static List<Category> buildNestedTree(List<Category> categories) {
    final childrenByParent = _indexChildren(categories);
    final roots = categories.where((category) => category.parentId == null);
    return roots
        .map((root) => _buildBranch(root, childrenByParent, const {}))
        .toList(growable: false);
  }

  static List<CategorySearchResult> search(
    List<Category> categories,
    String query,
  ) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final categoriesById = <int, Category>{
      for (final category in categories)
        if (category.id != null) category.id!: category,
    };
    final childrenByParent = _indexChildren(categories);
    final matches = categories
        .where(
          (category) => category.name.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);

    return matches
        .map(
          (match) => _buildSearchResult(
            match,
            categoriesById,
            childrenByParent,
          ),
        )
        .toList(growable: false);
  }

  static List<Category> findAncestors(
    Category category,
    Map<int, Category> categoriesById,
  ) {
    final ancestors = <Category>[];
    final visited = <int>{};
    var parentId = category.parentId;
    while (parentId != null && visited.add(parentId)) {
      final parent = categoriesById[parentId];
      if (parent == null) {
        break;
      }
      ancestors.add(parent);
      parentId = parent.parentId;
    }
    return ancestors.reversed.toList(growable: false);
  }

  static List<Category> findDescendants(
    Category category,
    Map<int, List<Category>> childrenByParent,
  ) {
    final descendants = <Category>[];
    final visited = <int>{if (category.id != null) category.id!};

    void visit(Category parent) {
      final parentId = parent.id;
      if (parentId == null) {
        return;
      }
      for (final child in childrenByParent[parentId] ?? const <Category>[]) {
        final childId = child.id;
        if (childId != null && visited.add(childId)) {
          descendants.add(child);
          visit(child);
        }
      }
    }

    visit(category);
    return descendants;
  }

  static List<Category> buildHierarchyPath(
    Category category,
    Map<int, Category> categoriesById,
  ) {
    return [...findAncestors(category, categoriesById), category];
  }

  static CategorySearchResult _buildSearchResult(
    Category match,
    Map<int, Category> categoriesById,
    Map<int, List<Category>> childrenByParent,
  ) {
    final ancestors = findAncestors(match, categoriesById);
    final descendants = findDescendants(match, childrenByParent);
    final matchWithChildren = _buildBranch(
      match,
      childrenByParent,
      const {},
    );
    final hierarchyPath = [...ancestors, matchWithChildren];

    var hierarchy = hierarchyPath.last;
    for (var index = hierarchyPath.length - 2; index >= 0; index--) {
      final ancestor = hierarchyPath[index];
      hierarchy = _copyWithChildren(ancestor, [hierarchy]);
    }

    return CategorySearchResult(
      category: match,
      ancestors: ancestors,
      directChildren: childrenByParent[match.id] ?? const [],
      descendants: descendants,
      hierarchyPath: [...ancestors, match],
      hierarchy: hierarchy,
    );
  }

  static Map<int, List<Category>> _indexChildren(List<Category> categories) {
    final childrenByParent = <int, List<Category>>{};
    for (final category in categories) {
      final parentId = category.parentId;
      if (parentId != null) {
        childrenByParent.putIfAbsent(parentId, () => []).add(category);
      }
    }
    return childrenByParent;
  }

  static Category _buildBranch(
    Category category,
    Map<int, List<Category>> childrenByParent,
    Set<int> ancestors,
  ) {
    final id = category.id;
    if (id == null || ancestors.contains(id)) {
      return _copyWithChildren(category, const []);
    }
    final nextAncestors = {...ancestors, id};
    final children = (childrenByParent[id] ?? const <Category>[])
        .map(
          (child) => _buildBranch(child, childrenByParent, nextAncestors),
        )
        .toList(growable: false);
    return _copyWithChildren(category, children);
  }

  static Category _copyWithChildren(
    Category category,
    List<Category> children,
  ) {
    return Category(
      id: category.id,
      name: category.name,
      parentId: category.parentId,
      createdAt: category.createdAt,
      userId: category.userId,
      children: children,
    );
  }
}
