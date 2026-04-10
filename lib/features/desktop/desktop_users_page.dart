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
      subtitle: 'Manage roles and accounts for the terminal.',
      actionLabel: 'Add user',
      onAction: canManage ? onAdd : null,
      items: users,
      itemBuilder: (user) => DesktopSimpleTile(
        title: user.name,
        subtitle: '${user.badgeId} • ${user.role.name}',
        status: user.isActive ? 'Active' : 'Inactive',
        onEdit: canManage ? () => onEdit(user: user) : null,
        onDelete: canManage ? () => onDelete(user) : null,
      ),
    );
  }
}
