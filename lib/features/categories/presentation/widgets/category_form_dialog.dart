import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({
    required this.categories,
    this.category,
    this.initialParentId,
    super.key,
  });

  final List<Category> categories;
  final Category? category;
  final int? initialParentId;

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int? _selectedParentId;
  bool _submitting = false;
  String? _operationError;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedParentId = widget.category?.parentId ?? widget.initialParentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Set<int> _excludedParentIds() {
    final categoryId = widget.category?.id;
    if (categoryId == null) {
      return const {};
    }

    final excluded = <int>{categoryId};
    var pending = <int>[categoryId];
    while (pending.isNotEmpty) {
      final children = widget.categories
          .where((category) => pending.contains(category.parentId))
          .map((category) => category.id)
          .whereType<int>()
          .where(excluded.add)
          .toList(growable: false);
      pending = children;
    }
    return excluded;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _operationError = null;
    });

    final bloc = context.read<CategoryBloc>();
    final name = _nameController.text.trim();
    final category = widget.category;
    if (category == null) {
      bloc.add(AddCategory(name: name, parentId: widget.initialParentId));
    } else {
      bloc.add(
        UpdateCategory(
          id: category.id!,
          name: name,
          parentId: _selectedParentId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final isWide = MediaQuery.sizeOf(context).width > 600;

    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (!_submitting) {
          return;
        }
        if (state is CategoryOperationSuccess) {
          Navigator.of(context).pop();
        } else if (state is CategoryError) {
          setState(() {
            _submitting = false;
            _operationError = state.message;
          });
        }
      },
      child: AlertDialog(
        scrollable: true,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 20,
          vertical: 24,
        ),
        title: Text(_isEditing ? 'Edit category' : 'Add category'),
        content: SizedBox(
          width: isWide ? 420 : null,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const ValueKey('category-name-field'),
                  controller: _nameController,
                  autofocus: true,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    hintText: 'For example, Books',
                    prefixIcon: Icon(Icons.folder_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category name cannot be empty.';
                    }
                    return null;
                  },
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: _selectedParentId,
                    decoration: const InputDecoration(
                      labelText: 'Parent category',
                      prefixIcon: Icon(Icons.account_tree_outlined),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Root category'),
                      ),
                      ..._eligibleParents().map(
                        (candidate) => DropdownMenuItem<int?>(
                          value: candidate.id,
                          child: Text(candidate.name),
                        ),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (parentId) => setState(() {
                              _selectedParentId = parentId;
                            }),
                  ),
                ],
                if (category == null && widget.initialParentId != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'This will be added under '
                    '${_categoryName(widget.initialParentId)}.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (_operationError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _operationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Save changes' : 'Add category'),
          ),
        ],
      ),
    );
  }

  List<Category> _eligibleParents() {
    final excluded = _excludedParentIds();
    return widget.categories
        .where(
          (candidate) =>
              candidate.id != null && !excluded.contains(candidate.id),
        )
        .toList(growable: false);
  }

  String _categoryName(int? id) {
    for (final category in widget.categories) {
      if (category.id == id) {
        return category.name;
      }
    }
    return 'the selected category';
  }
}
