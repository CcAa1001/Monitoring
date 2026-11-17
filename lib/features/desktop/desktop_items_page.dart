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
      title: tr('Barang'),
      subtitle: tr('Kelola katalog peralatan, registrasi QR, dan penempatan barang saat ini.'),
      actionLabel: tr('Daftarkan barang'),
      onAction: canManage ? onAdd : null,
      items: items,
      searchHint: tr('Cari nama, QR, nomor seri, merek, model, kategori, atau lokasi'),
      searchText: (item) => <String>[
        item.name,
        item.qrCode,
        item.serialNumber ?? '',
        item.brand ?? '',
        item.model ?? '',
        item.category,
        item.currentLocation,
        item.condition ?? '',
      ].join(' '),
      itemBuilder: (item) => DesktopSimpleTile(
        title: item.name,
        subtitle: '${item.qrCode} | ${item.serialNumber ?? tr('Tanpa nomor seri')} | ${item.brand ?? tr('Tanpa merek')} | ${item.currentLocation}',
        status: itemStatusLabel(item),
        onHistory: () => onViewHistory(item),
        onEdit: canManage ? () => onEdit(item: item) : null,
        onDelete: canManage ? () => onDelete(item) : null,
      ),
    );
  }
}

class DesktopSimpleListPage<T> extends StatefulWidget {
  const DesktopSimpleListPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.items,
    required this.searchHint,
    required this.searchText,
    required this.itemBuilder,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final List<T> items;
  final String searchHint;
  final String Function(T item) searchText;
  final Widget Function(T item) itemBuilder;

  @override
  State<DesktopSimpleListPage<T>> createState() => _DesktopSimpleListPageState<T>();
}

class _DesktopSimpleListPageState<T> extends State<DesktopSimpleListPage<T>> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.items;
    return widget.items.where((item) => widget.searchText(item).toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    return ListView(
      children: <Widget>[
        DesktopSectionHeader(
          title: widget.title,
          subtitle: widget.subtitle,
        ),
        const SizedBox(height: 18),
        DesktopPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      tr('Daftar {title}', {'title': widget.title}),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  if (widget.onAction != null)
                    FilledButton.icon(
                      onPressed: widget.onAction,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(widget.actionLabel),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tr('Menampilkan {shown} dari {total} data.', {'shown': filteredItems.length, 'total': widget.items.length}),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: widget.searchHint,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              if (filteredItems.isEmpty)
                const _DesktopListEmptyState()
              else
                ...filteredItems.map(widget.itemBuilder),
            ],
          ),
        ),
      ],
    );
  }
}

class _DesktopListEmptyState extends StatelessWidget {
  const _DesktopListEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(
        tr('Tidak ada data yang cocok dengan pencarian saat ini.'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
