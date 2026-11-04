import 'package:flutter/material.dart';

import '../../domain/entities/category.dart';

class CategoryTreeNode extends StatelessWidget {
  const CategoryTreeNode({
    required this.category,
    required this.depth,
    required this.hasChildren,
    required this.childCount,
    required this.expanded,
    required this.enabled,
    required this.onToggle,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Category category;
  final int depth;
  final bool hasChildren;
  final int childCount;
  final bool expanded;
  final bool enabled;
  final VoidCallback? onToggle;
  final VoidCallback onAddChild;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRoot = depth == 0;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(12 + depth * 24, 3, 12, 3),
      child: Material(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: hasChildren ? onToggle : null,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 5, 6, 5),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: hasChildren
                      ? IconButton(
                          tooltip: expanded ? 'Collapse' : 'Expand',
                          onPressed: onToggle,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            expanded ? Icons.expand_more : Icons.chevron_right,
                          ),
                        )
                      : Icon(
                          Icons.subdirectory_arrow_right,
                          size: 18,
                          color: colors.outline,
                        ),
                ),
                Icon(
                  isRoot ? Icons.folder_outlined : Icons.folder_open_outlined,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  isRoot ? FontWeight.w700 : FontWeight.w500,
                            ),
                      ),
                      if (hasChildren)
                        Text(
                          '$childCount '
                          '${childCount == 1 ? 'subitem' : 'subitems'}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                        ),
                    ],
                  ),
                ),
                if (MediaQuery.sizeOf(context).width - depth * 24 < 620)
                  PopupMenuButton<_CategoryAction>(
                    tooltip: 'Category actions',
                    enabled: enabled,
                    onSelected: (action) {
                      switch (action) {
                        case _CategoryAction.addChild:
                          onAddChild();
                        case _CategoryAction.edit:
                          onEdit();
                        case _CategoryAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: _CategoryAction.addChild,
                        child: ListTile(
                          leading: Icon(Icons.create_new_folder_outlined),
                          title: Text('Add subcategory'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: _CategoryAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                        ),
                      ),
                      PopupMenuItem(
                        value: _CategoryAction.delete,
                        child: ListTile(
                          leading:
                              Icon(Icons.delete_outline, color: colors.error),
                          title: const Text('Delete'),
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert),
                  )
                else ...[
                  _NodeAction(
                    tooltip: 'Add subcategory to ${category.name}',
                    icon: Icons.create_new_folder_outlined,
                    onPressed: enabled ? onAddChild : null,
                  ),
                  _NodeAction(
                    tooltip: 'Edit ${category.name}',
                    icon: Icons.edit_outlined,
                    onPressed: enabled ? onEdit : null,
                  ),
                  _NodeAction(
                    tooltip: 'Delete ${category.name}',
                    icon: Icons.delete_outline,
                    onPressed: enabled ? onDelete : null,
                    color: colors.error,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CategoryAction { addChild, edit, delete }

class _NodeAction extends StatelessWidget {
  const _NodeAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      color: color,
      icon: Icon(icon),
    );
  }
}
