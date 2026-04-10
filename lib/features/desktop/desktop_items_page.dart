part of 'desktop_shell_screen_v2.dart';

class DesktopItemsPage extends StatelessWidget {
  const DesktopItemsPage({
    super.key,
    required this.items,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onViewHistory,
  });

  final List<Item> items;
  final bool canManage;
  final VoidCallback onAdd;
  final Future<void> Function({Item? item}) onEdit;
  final Future<void> Function(Item item) onDelete;
  final Future<void> Function(Item item) onViewHistory;

  @override
  Widget build(BuildContext context) {
    return DesktopSimpleListPage<Item>(
      title: 'Items',
      subtitle: 'Register, edit, and maintain equipment with scanned QR, category, and location options.',
      actionLabel: 'Register item',
      onAction: canManage ? onAdd : null,
      items: items,
      itemBuilder: (item) => DesktopSimpleTile(
        title: item.name,
        subtitle: '${item.qrCode} • ${item.category} • ${item.currentLocation}',
        status: item.status == ItemStatus.available ? 'Ready' : 'Borrowed',
        onHistory: () => onViewHistory(item),
        onEdit: canManage ? () => onEdit(item: item) : null,
        onDelete: canManage ? () => onDelete(item) : null,
      ),
    );
  }
}

class DesktopSimpleListPage<T> extends StatelessWidget {
  const DesktopSimpleListPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.items,
    required this.itemBuilder,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final List<T> items;
  final Widget Function(T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: DesktopSectionHeader(
                title: title,
                subtitle: subtitle,
              ),
            ),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ],
        ),
        const SizedBox(height: 18),
        DesktopPanel(
          title: title,
          child: Column(
            children: items.map(itemBuilder).toList(),
          ),
        ),
      ],
    );
  }
}
