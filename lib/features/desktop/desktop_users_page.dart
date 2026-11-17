part of 'desktop_shell_screen_v2.dart';

class DesktopUsersPage extends StatelessWidget {
  const DesktopUsersPage({
    super.key,
    required this.users,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<AppUser> users;
  final bool canManage;
  final VoidCallback onAdd;
  final Future<void> Function({AppUser? user}) onEdit;
  final Future<void> Function(AppUser user) onDelete;

  @override
  Widget build(BuildContext context) {
    return DesktopSimpleListPage<AppUser>(
      title: 'Pengguna',
      subtitle: 'Atur siapa yang dapat mengoperasikan meja, apa yang dapat mereka ubah, dan akun mana yang tetap aktif.',
      actionLabel: 'Tambah pengguna',
      onAction: canManage ? onAdd : null,
      items: users,
      searchHint: 'Cari nama, ID badge, peran, atau status',
      searchText: (user) => '${user.name} ${user.badgeId} ${user.role.label} ${user.isActive ? 'aktif' : 'nonaktif'}',
      itemBuilder: (user) => DesktopSimpleTile(
        title: user.name,
        subtitle: '${user.badgeId} | ${user.role.label}',
        status: user.isActive ? 'Aktif' : 'Nonaktif',
        onEdit: canManage ? () => onEdit(user: user) : null,
        onDelete: canManage ? () => onDelete(user) : null,
      ),
    );
  }
}
