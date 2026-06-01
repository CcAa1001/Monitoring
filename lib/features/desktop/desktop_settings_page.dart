part of 'desktop_shell_screen_v2.dart';

class DesktopSettingsPage extends StatelessWidget {
  const DesktopSettingsPage({
    super.key,
    required this.pairingSession,
    required this.themeMode,
    required this.currentUser,
    required this.onLogout,
  });

  final PairingSession? pairingSession;
  final ThemeMode themeMode;
  final AppUser currentUser;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      children: <Widget>[
        const DesktopSectionHeader(
          title: 'Settings',
          subtitle: 'Review the current terminal state, operator account, and pairing environment.',
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 7,
              child: DesktopPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Terminal profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'These values describe the workstation session that is currently active on this desk.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _SettingsInfoCard(
                            icon: Icons.palette_outlined,
                            label: 'Theme mode',
                            value: themeMode == ThemeMode.dark ? 'Dark' : 'Light',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SettingsInfoCard(
                            icon: Icons.person_outline_rounded,
                            label: 'Signed in as',
                            value: currentUser.name,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SettingsInfoCard(
                            icon: Icons.badge_outlined,
                            label: 'Badge ID',
                            value: currentUser.badgeId,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B2236) : const Color(0xFFFBFBFE),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2A314B) : const Color(0xFFECEFF6),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Session control',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Use this only when the current terminal operator is done and the desk needs to return to sign in.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: onLogout,
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Log out terminal'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: DesktopPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Pairing state',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pairingSession == null
                          ? 'No phone pairing is active right now.'
                          : 'This terminal has an active phone pairing session ready for remote scanning.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    _DesktopPairingSummary(
                      pairingSession: pairingSession,
                      emptyMessage: 'No pair code has been created yet. Start pairing from the dashboard when you want to connect a roaming phone scanner.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  const _SettingsInfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2236) : const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A314B) : const Color(0xFFECEFF6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5B39EA).withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF5B39EA)),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1F2533),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
