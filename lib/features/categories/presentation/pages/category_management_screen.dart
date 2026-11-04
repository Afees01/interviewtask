import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_search_result.dart';
import '../../domain/utils/category_hierarchy.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_tree_node.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _searchController = TextEditingController();
  final Set<int> _expandedCategoryIds = {};
  List<Category> _categories = const [];
  bool _initializedTree = false;
  bool _categoryFormOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const LoadCategories());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCategoryForm({
    Category? category,
    int? parentId,
  }) async {
    setState(() => _categoryFormOpen = true);
    try {
      await showDialog<void>(
        context: context,
        builder: (context) => CategoryFormDialog(
          categories: _categories,
          category: category,
          initialParentId: parentId,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _categoryFormOpen = false);
      }
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete category?'),
        content: Text(
          'Delete "${category.name}" and all of its nested subcategories? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<CategoryBloc>().add(DeleteCategory(category.id!));
    }
  }

  void _onCategoryState(BuildContext context, CategoryState state) {
    if (state is CategoryInitial) {
      setState(() {
        _categories = const [];
        _expandedCategoryIds.clear();
        _initializedTree = false;
      });
    } else if (state is CategoryLoaded) {
      setState(() {
        _categories = state.categories;
        if (!_initializedTree) {
          _expandedCategoryIds.addAll(
            state.categories
                .where((category) => category.parentId == null)
                .map((category) => category.id)
                .whereType<int>(),
          );
          _initializedTree = true;
        }
      });
    } else if (state is CategoryOperationSuccess) {
      _searchController.clear();
      setState(() {});
      final category = state.category;
      if (category != null) {
        setState(() {
          final expandedId = category.parentId ?? category.id;
          if (expandedId != null) {
            _expandedCategoryIds.add(expandedId);
          }
        });
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.message)));
      final bloc = context.read<CategoryBloc>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          bloc.add(const LoadCategories());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final query = _searchController.text.trim().toLowerCase();

    return BlocListener<CategoryBloc, CategoryState>(
      listener: _onCategoryState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          actions: [
            IconButton(
              tooltip: 'Profile',
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.account_circle_outlined),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (_categories.isEmpty &&
                      state is CategoryLoading &&
                      !_initializedTree) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_categories.isEmpty && state is CategoryError) {
                    return _LoadError(
                      message: state.message,
                      onRetry: () => context
                          .read<CategoryBloc>()
                          .add(const LoadCategories()),
                    );
                  }

                  final isLoading = state is CategoryLoading ||
                      state is CategorySearchLoading;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isLoading) const LinearProgressIndicator(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 520;
                            final heading = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your categories',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_categories.length} '
                                  '${_categories.length == 1 ? 'category' : 'categories'} '
                                  'in your collection',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: colors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            );
                            final addButton = FilledButton.icon(
                              onPressed:
                                  isLoading ? null : () => _showCategoryForm(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add category'),
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  heading,
                                  const SizedBox(height: 16),
                                  addButton,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: heading),
                                addButton,
                              ],
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {});
                            final bloc = context.read<CategoryBloc>();
                            if (value.trim().isEmpty) {
                              bloc.add(const ClearCategorySearch());
                            } else {
                              bloc.add(SearchCategories(value));
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Search categories',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                      context
                                          .read<CategoryBloc>()
                                          .add(const ClearCategorySearch());
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                            filled: true,
                          ),
                        ),
                      ),
                      if (state is CategoryError &&
                          _categories.isNotEmpty &&
                          !_categoryFormOpen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Material(
                            color: colors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                state.message,
                                style:
                                    TextStyle(color: colors.onErrorContainer),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: query.isNotEmpty
                            ? _buildSearchContent(state, query, isLoading)
                            : _buildTreeContent(
                                CategoryHierarchy.buildNestedTree(_categories),
                                isLoading: isLoading,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTreeContent(
    List<Category> tree, {
    required bool isLoading,
  }) {
    if (_categories.isEmpty) {
      return _EmptyCategories(
        onAdd: isLoading ? null : () => _showCategoryForm(),
      );
    }
    if (tree.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No categories match your search.'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
      children: [
        for (final item in tree)
          _buildCategoryNode(item, depth: 0, isLoading: isLoading),
      ],
    );
  }

  Widget _buildSearchContent(
    CategoryState state,
    String query,
    bool isLoading,
  ) {
    if (state is CategorySearchLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Searching categories...'),
          ],
        ),
      );
    }
    if (state is CategorySearchError) {
      return _LoadError(
        message: state.message,
        onRetry: () =>
            context.read<CategoryBloc>().add(SearchCategories(query)),
      );
    }
    if (state is CategorySearchEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48),
              const SizedBox(height: 12),
              Text(
                'No categories found for "$query".',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (state is CategorySearchSuccess) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              '${state.results.length} '
              '${state.results.length == 1 ? 'match' : 'matches'}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final result in state.results)
            _buildSearchResult(result, isLoading: isLoading),
        ],
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildSearchResult(
    CategorySearchResult result, {
    required bool isLoading,
  }) {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Matched category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Text(
                    '${result.hierarchyPath.length} '
                    '${result.hierarchyPath.length == 1 ? 'level' : 'levels'}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Text(
                result.hierarchyPath
                    .map((category) => category.name)
                    .join(' › '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            _buildCategoryNode(
              result.hierarchy,
              depth: 0,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryNode(
    Category category, {
    required int depth,
    required bool isLoading,
  }) {
    final id = category.id;
    final expanded = id != null && _expandedCategoryIds.contains(id);
    final children = category.children;

    return Column(
      key: id == null ? null : ValueKey('category-$id'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryTreeNode(
          category: category,
          depth: depth,
          hasChildren: children.isNotEmpty,
          childCount: children.length,
          expanded: expanded,
          enabled: !isLoading,
          onToggle: id == null
              ? null
              : () {
                  setState(() {
                    if (expanded) {
                      _expandedCategoryIds.remove(id);
                    } else {
                      _expandedCategoryIds.add(id);
                    }
                  });
                },
          onAddChild: () => _showCategoryForm(parentId: id),
          onEdit: () => _showCategoryForm(category: category),
          onDelete: () => _confirmDelete(category),
        ),
        if (expanded || _searchController.text.trim().isNotEmpty)
          for (final child in children)
            _buildCategoryNode(
              child,
              depth: depth + 1,
              isLoading: isLoading,
            ),
      ],
    );
  }
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No categories yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a category to start organizing your collection.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Create first category'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
