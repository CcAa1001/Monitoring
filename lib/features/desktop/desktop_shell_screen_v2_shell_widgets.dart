part of 'desktop_shell_screen_v2.dart';

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleColor = isDark ? const Color(0xFFB3BCD4) : const Color(0xFF9197B3);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF5B39EA) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: selected ? Colors.white : idleColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: selected ? Colors.white : idleColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadErrorState extends StatelessWidget {
  const _LoadErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Desktop data could not load',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'The desktop screen is reachable, but one of the data sources failed. This often happens when a new Supabase table or column has not been created yet.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFEA5455),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry loading'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.user,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onOpenProfileMenu,
  });

  final AppUser user;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onOpenProfileMenu;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            _pageTitle(context),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F2533),
            ),
          ),
        ),
        IconButton(
          onPressed: onToggleTheme,
          icon: Icon(
            themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => onOpenProfileMenu(),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: const Color(0xFFF0ECFF),
                  foregroundColor: const Color(0xFF5B39EA),
                  child: Text(user.name.isEmpty ? 'U' : user.name.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${user.badgeId} | ${user.role.name}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7E8698),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _pageTitle(BuildContext context) {
    final state = context.findAncestorStateOfType<_DesktopShellScreenState>();
    if (state == null) return 'Dashboard';
    return state._menuLabel(state._selectedMenu);
  }
}
