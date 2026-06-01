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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      children: <Widget>[
        const DesktopSectionHeader(
          title: 'Roles',
          subtitle: 'Define which responsibilities belong to admins, operators, and read-only viewers.',
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
                      'Permission matrix',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => onAddRole(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add role'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Each role below describes what the terminal can expose, edit, and submit while that user is signed in.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              ...roles.map(
                (role) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1B2236) : const Color(0xFFFBFBFE),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2A314B) : const Color(0xFFECEFF6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B39EA).withValues(alpha: isDark ? 0.18 : 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.shield_rounded, color: Color(0xFF5B39EA)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  role.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF1F2533),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${role.permissions.length} menu permissions configured',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: role.permissions
                            .map(
                              (permission) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF232B45) : const Color(0xFFF2EEFF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  permission,
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFFD3D8FF) : const Color(0xFF5B39EA),
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
