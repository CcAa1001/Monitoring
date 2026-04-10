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
    return ListView(
      children: <Widget>[
        const DesktopSectionHeader(
          title: 'Settings',
          subtitle: 'Operational policies and environment details for the equipment-room terminal.',
        ),
        const SizedBox(height: 18),
        DesktopPanel(
          title: 'Current state',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Theme mode: ${themeMode == ThemeMode.dark ? 'Dark' : 'Light'}'),
              const SizedBox(height: 8),
              Text('Signed in as: ${currentUser.name} (${currentUser.badgeId})'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log out from this terminal'),
              ),
              const SizedBox(height: 12),
              Text(
                pairingSession == null
                    ? 'No active phone pairing session.'
                    : 'Pair code ${pairingSession!.code} • Device ${pairingSession!.connectedDeviceName ?? 'waiting'}',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
