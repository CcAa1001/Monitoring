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
      title: 'Users',
      subtitle: 'Control who can operate the desk, what they can change, and which accounts remain active.',
      actionLabel: 'Add user',
      onAction: canManage ? onAdd : null,
      items: users,
      searchHint: 'Search name, badge ID, role, or status',
      searchText: (user) => '${user.name} ${user.badgeId} ${user.role.name} ${user.isActive ? 'active' : 'inactive'}',
      itemBuilder: (user) => DesktopSimpleTile(
        title: user.name,
        subtitle: '${user.badgeId} | ${user.role.name}',
        status: user.isActive ? 'Active' : 'Inactive',
        onEdit: canManage ? () => onEdit(user: user) : null,
        onDelete: canManage ? () => onDelete(user) : null,
      ),
    );
  }
}
