import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/category_search_result.dart';
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
  final _searchFocusNode = FocusNode();
  final Set<int> _expandedCategoryIds = {};
  List<Category> _categories = const [];
  Timer? _searchDebounce;
  bool _initializedTree = false;
  bool _categoryFormOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(const LoadCategories());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) {
        return;
      }
      final bloc = context.read<CategoryBloc>();
      if (value.trim().isEmpty) {
        bloc.add(const ClearCategorySearch());
      } else {
        bloc.add(SearchCategories(value));
      }
    });
  }

  void _clearSearch({bool notifyBloc = true}) {
    _searchDebounce?.cancel();
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
    }
    _searchFocusNode.unfocus();
    if (notifyBloc && mounted) {
      context.read<CategoryBloc>().add(const ClearCategorySearch());
    }
  }

  Future<void> _showCategoryForm({
    Category? category,
    int? parentId,
  }) async {
    _searchFocusNode.unfocus();
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
    FocusManager.instance.primaryFocus?.unfocus();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
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
      _clearSearch(notifyBloc: false);
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
      _clearSearch(notifyBloc: false);
      final category = state.category;
      if (category != null) {
        final expandedId = category.parentId ?? category.id;
        if (expandedId != null) {
          _expandedCategoryIds.add(expandedId);
        }
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(state.message),
          ),
        );
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
    return BlocListener<CategoryBloc, CategoryState>(
      listener: _onCategoryState,
      child: Scaffold(
        body: SafeArea(
          top: false,
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (_categories.isEmpty &&
                      !_initializedTree &&
                      (state is CategoryLoading || state is CategoryInitial)) {
                    return const CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    );
                  }
                  if (_categories.isEmpty &&
                      !_initializedTree &&
                      state is CategoryError) {
                    return CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _LoadError(
                            message: state.message,
                            onRetry: () => context
                                .read<CategoryBloc>()
                                .add(const LoadCategories()),
                          ),
                        ),
                      ],
                    );
                  }

                  final query = _searchController.text.trim();
                  final isLoading = state is CategoryLoading ||
                      state is CategorySearchLoading;
                  final showErrorBanner = state is CategoryError &&
                      _categories.isNotEmpty &&
                      !_categoryFormOpen;

                  return CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 4,
                          child: isLoading
                              ? const LinearProgressIndicator()
                              : null,
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildHeading(context)),
                      SliverToBoxAdapter(child: _buildSearchField()),
                      if (showErrorBanner)
                        SliverToBoxAdapter(
                          child: _buildErrorBanner(
                            context,
                            state.message,
                          ),
                        ),
                      if (query.isEmpty)
                        ..._buildCategorySlivers(isLoading)
                      else
                        ..._buildSearchSlivers(state, query, isLoading),
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

  Widget _buildHeading(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
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
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          );
          final addButton = FilledButton.icon(
            onPressed: _categoryFormOpen ? null : () => _showCategoryForm(),
            icon: const Icon(Icons.add),
            label: const Text('Add category'),
          );

          if (constraints.maxWidth < 520) {
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
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: TextField(
        key: const ValueKey('category-search-field'),
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search categories',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) => value.text.trim().isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close),
                  ),
          ),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Material(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: colors.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategorySlivers(bool isLoading) {
    if (_categories.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _EmptyCategories(
            onAdd: isLoading || _categoryFormOpen ? null : _showCategoryForm,
          ),
        ),
      ];
    }

    final rows = _visibleCategoryRows();
    if (rows.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No categories to display.')),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildCategoryRow(
              rows[index],
              isLoading: isLoading,
            ),
            childCount: rows.length,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildSearchSlivers(
    CategoryState state,
    String query,
    bool isLoading,
  ) {
    if (state is CategorySearchLoading || state is CategoryLoading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (state is CategorySearchError) {
      return [
        SliverToBoxAdapter(
          child: _LoadError(
            message: state.message,
            onRetry: () =>
                context.read<CategoryBloc>().add(SearchCategories(query)),
          ),
        ),
      ];
    }
    if (state is CategorySearchEmpty) {
      return [
        SliverToBoxAdapter(child: _SearchEmpty(query: query)),
      ];
    }
    if (state is! CategorySearchSuccess) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }

    final rows = _searchDisplayRows(state.results);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            '${state.results.length} '
            '${state.results.length == 1 ? 'match' : 'matches'}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final row = rows[index];
              final result = row.result;
              if (result != null) {
                return _buildSearchResultHeader(result, row.key);
              }
              return _buildCategoryRow(
                _CategoryRow(
                  category: row.category!,
                  depth: row.depth,
                  expanded: true,
                  childCount: row.childCount,
                  key: row.key,
                  forceExpanded: true,
                ),
                isLoading: isLoading,
              );
            },
            childCount: rows.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildSearchResultHeader(CategorySearchResult result, String key) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey(key),
      elevation: 0,
      color: colors.primaryContainer,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Matched: ${result.category.name}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              result.hierarchyPath.map((category) => category.name).join(' › '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${result.hierarchyPath.length} '
              '${result.hierarchyPath.length == 1 ? 'level' : 'levels'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<_CategoryRow> _visibleCategoryRows() {
    final childrenByParent = <int, List<Category>>{};
    final roots = <Category>[];
    for (final category in _categories) {
      final parentId = category.parentId;
      if (parentId == null) {
        roots.add(category);
      } else {
        childrenByParent.putIfAbsent(parentId, () => []).add(category);
      }
    }

    final pending = <_PendingCategory>[
      for (var index = roots.length - 1; index >= 0; index--)
        _PendingCategory(roots[index], 0, 'category'),
    ];
    return _flattenPending(pending, childrenByParent);
  }

  List<_SearchDisplayRow> _searchDisplayRows(
    List<CategorySearchResult> results,
  ) {
    final rows = <_SearchDisplayRow>[];
    for (final result in results) {
      final matchId = result.category.id;
      rows.add(
        _SearchDisplayRow.header(
          result,
          'search-result-${matchId ?? result.category.name}',
        ),
      );
      final childrenByParent = <int, List<Category>>{};
      final pending = <_PendingCategory>[
        _PendingCategory(
          result.hierarchy,
          0,
          'search-${matchId ?? result.category.name}',
        ),
      ];
      final flattened = _flattenPending(
        pending,
        childrenByParent,
        forceExpand: true,
      );
      rows.addAll(
        flattened.map(
          (row) => _SearchDisplayRow.category(
            row.category,
            row.depth,
            row.childCount,
            '${row.key}--${row.category.id}',
          ),
        ),
      );
    }
    return rows;
  }

  List<_CategoryRow> _flattenPending(
    List<_PendingCategory> pending,
    Map<int, List<Category>> childrenByParent, {
    bool forceExpand = false,
  }) {
    final rows = <_CategoryRow>[];
    final visited = <int>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      final category = current.category;
      final id = category.id;
      if (id != null && !visited.add(id)) {
        continue;
      }
      final children = childrenByParent.isEmpty
          ? category.children
          : (id == null ? const <Category>[] : childrenByParent[id] ?? []);
      final expanded =
          forceExpand || (id != null && _expandedCategoryIds.contains(id));
      rows.add(
        _CategoryRow(
          category: category,
          depth: current.depth,
          expanded: expanded,
          childCount: children.length,
          key: '${current.keyPrefix}-${id ?? current.depth}',
          forceExpanded: forceExpand,
        ),
      );

      if (expanded) {
        for (var index = children.length - 1; index >= 0; index--) {
          pending.add(
            _PendingCategory(
              children[index],
              current.depth + 1,
              current.keyPrefix,
            ),
          );
        }
      }
    }
    return rows;
  }

  Widget _buildCategoryRow(
    _CategoryRow row, {
    required bool isLoading,
  }) {
    final category = row.category;
    final id = category.id;
    final hasChildren = row.childCount > 0;
    return Padding(
      key: ValueKey(row.key),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: CategoryTreeNode(
        category: category,
        depth: row.depth,
        hasChildren: hasChildren,
        childCount: row.childCount,
        expanded: row.expanded,
        enabled: !isLoading && !_categoryFormOpen,
        onToggle: id == null || row.forceExpanded
            ? null
            : () {
                setState(() {
                  if (row.expanded) {
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
    );
  }
}

class _PendingCategory {
  const _PendingCategory(this.category, this.depth, this.keyPrefix);

  final Category category;
  final int depth;
  final String keyPrefix;
}

class _CategoryRow {
  const _CategoryRow({
    required this.category,
    required this.depth,
    required this.expanded,
    required this.childCount,
    required this.key,
    this.forceExpanded = false,
  });

  final Category category;
  final int depth;
  final bool expanded;
  final int childCount;
  final String key;
  final bool forceExpanded;
}

class _SearchDisplayRow {
  const _SearchDisplayRow.header(this.result, this.key)
      : category = null,
        depth = 0,
        childCount = 0;

  const _SearchDisplayRow.category(
    this.category,
    this.depth,
    this.childCount,
    this.key,
  ) : result = null;

  final CategorySearchResult? result;
  final Category? category;
  final int depth;
  final int childCount;
  final String key;
}

class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).height < 600;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 16 : 22),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_tree_outlined,
                size: compact ? 36 : 48,
                color: colors.onPrimaryContainer,
              ),
            ),
            SizedBox(height: compact ? 12 : 20),
            Text(
              'No categories yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a category to start organizing your collection.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: compact ? 12 : 20),
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

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 44),
          const SizedBox(height: 12),
          Text(
            'No categories found for "$query".',
            textAlign: TextAlign.center,
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
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
