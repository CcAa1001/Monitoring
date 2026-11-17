part of 'desktop_shell_screen_v2.dart';

class DesktopLocationsPage extends StatelessWidget {
  const DesktopLocationsPage({
    super.key,
    required this.locations,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AllowedLocation> locations;
  final bool canManage;
  final VoidCallback onAdd;
  final Future<void> Function({AllowedLocation? location}) onEdit;
  final Future<void> Function(AllowedLocation location) onDelete;

  @override
  Widget build(BuildContext context) {
    return DesktopSimpleListPage<AllowedLocation>(
      title: tr('Lokasi'),
      subtitle: tr('Tentukan rak dan line tujuan yang boleh dipakai untuk pergerakan barang.'),
      actionLabel: tr('Tambah lokasi'),
      onAction: canManage ? onAdd : null,
      items: locations,
      searchHint: tr('Cari kode lokasi, tipe, atau status'),
      searchText: (location) => <String>[
        location.code,
        location.type == LocationType.line ? tr('line tujuan produksi') : tr('rak penyimpanan'),
        location.isActive ? tr('aktif') : tr('nonaktif'),
      ].join(' '),
      itemBuilder: (location) => DesktopSimpleTile(
        title: location.code,
        subtitle: location.type == LocationType.line ? tr('Line tujuan produksi') : tr('Rak penyimpanan'),
        status: location.isActive ? tr('Aktif') : tr('Nonaktif'),
        onEdit: canManage ? () => onEdit(location: location) : null,
        onDelete: canManage ? () => onDelete(location) : null,
      ),
    );
  }
}
