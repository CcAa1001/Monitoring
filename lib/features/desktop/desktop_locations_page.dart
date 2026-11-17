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
      title: 'Lokasi',
      subtitle: 'Tentukan rak dan line tujuan yang boleh dipakai untuk pergerakan barang.',
      actionLabel: 'Tambah lokasi',
      onAction: canManage ? onAdd : null,
      items: locations,
      searchHint: 'Cari kode lokasi, tipe, atau status',
      searchText: (location) => <String>[
        location.code,
        location.type == LocationType.line ? 'line tujuan produksi' : 'rak penyimpanan',
        location.isActive ? 'aktif' : 'nonaktif',
      ].join(' '),
      itemBuilder: (location) => DesktopSimpleTile(
        title: location.code,
        subtitle: location.type == LocationType.line ? 'Line tujuan produksi' : 'Rak penyimpanan',
        status: location.isActive ? 'Aktif' : 'Nonaktif',
        onEdit: canManage ? () => onEdit(location: location) : null,
        onDelete: canManage ? () => onDelete(location) : null,
      ),
    );
  }
}
