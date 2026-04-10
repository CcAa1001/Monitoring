part of 'desktop_shell_screen_v2.dart';

class DesktopReturnPage extends StatelessWidget {
  const DesktopReturnPage({
    super.key,
    required this.pairingSession,
    required this.onReturn,
    required this.role,
  });

  final PairingSession? pairingSession;
  final VoidCallback? onReturn;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const DesktopSectionHeader(
          title: 'Return',
          subtitle: 'Return items using the desktop camera or a paired phone scanner.',
        ),
        const SizedBox(height: 18),
        DesktopPanel(
          title: 'Return actions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Choose how to start the return queue.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: 240,
                    child: FilledButton.icon(
                      onPressed: onReturn,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan with PC camera'),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: OutlinedButton.icon(
                      onPressed: pairingSession == null ? null : onReturn,
                      icon: const Icon(Icons.phonelink_ring_rounded),
                      label: const Text('Scan with phone camera'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (role == UserRole.viewer) ...<Widget>[
          const DesktopPanel(
            title: 'Viewer access',
            child: Text(
              'This account can monitor and review records, but cannot return items. Use an operator or admin account at the equipment-room desk for transactions.',
            ),
          ),
          const SizedBox(height: 18),
        ],
        DesktopPanel(
          title: 'Pairing status',
          child: Text(
            pairingSession == null
                ? 'No phone is paired right now. Create a pairing session on the dashboard to show a desktop QR.'
                : 'Pair code: ${pairingSession!.code} • Device: ${pairingSession!.connectedDeviceName ?? 'waiting'} • Last scan: ${pairingSession!.lastScannedQr ?? '-'}',
          ),
        ),
      ],
    );
  }
}
