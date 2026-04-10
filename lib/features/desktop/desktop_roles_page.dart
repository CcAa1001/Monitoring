part of 'desktop_shell_screen_v2.dart';

class _RoleDefinition {
  const _RoleDefinition({
    required this.name,
    required this.permissions,
  });

  final String name;
  final List<String> permissions;
}

class _DesktopRolesPage extends StatelessWidget {
  const _DesktopRolesPage({
    required this.roles,
    required this.onAddRole,
  });

  final List<_RoleDefinition> roles;
  final Future<void> Function() onAddRole;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const DesktopSectionHeader(
          title: 'Roles',
          subtitle: 'Manage role definitions and permission sets.',
        ),
        const SizedBox(height: 18),
        DesktopPanel(
          title: 'Role definitions',
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () => onAddRole(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add role'),
                ),
              ),
              const SizedBox(height: 16),
              ...roles.map(
                (role) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        role.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: role.permissions
                            .map(
                              (permission) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0ECFF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  permission,
                                  style: const TextStyle(
                                    color: Color(0xFF5B39EA),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
