part of 'desktop_shell_screen_v2.dart';

class DesktopCategoriesPage extends StatelessWidget {
  const DesktopCategoriesPage({
    super.key,
    required this.categories,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ItemCategory> categories;
  final bool canManage;
  final VoidCallback onAdd;
  final Future<void> Function({ItemCategory? category}) onEdit;
  final Future<void> Function(ItemCategory category) onDelete;

  @override
  Widget build(BuildContext context) {
    return DesktopSimpleListPage<ItemCategory>(
      title: 'Categories',
      subtitle: 'Manage category options used when registering and editing items.',
      actionLabel: 'Add category',
      onAction: canManage ? onAdd : null,
      items: categories,
      itemBuilder: (category) => DesktopSimpleTile(
        title: category.name,
        subtitle: 'Item category option',
        status: category.isActive ? 'Active' : 'Inactive',
        onEdit: canManage ? () => onEdit(category: category) : null,
        onDelete: canManage ? () => onDelete(category) : null,
      ),
    );
  }
}
