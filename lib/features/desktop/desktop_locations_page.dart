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
      title: 'Locations',
      subtitle: 'Define the shelves, racks, and line destinations that movements are allowed to use.',
      actionLabel: 'Add location',
      onAction: canManage ? onAdd : null,
      items: locations,
      searchHint: 'Search location code, type, or status',
      searchText: (location) => <String>[
        location.code,
        location.type == LocationType.line ? 'line production destination' : 'rack storage destination',
        location.isActive ? 'active' : 'inactive',
      ].join(' '),
      itemBuilder: (location) => DesktopSimpleTile(
        title: location.code,
        subtitle: location.type == LocationType.line ? 'Production line destination' : 'Rack storage destination',
        status: location.isActive ? 'Active' : 'Inactive',
        onEdit: canManage ? () => onEdit(location: location) : null,
        onDelete: canManage ? () => onDelete(location) : null,
      ),
    );
  }
}
