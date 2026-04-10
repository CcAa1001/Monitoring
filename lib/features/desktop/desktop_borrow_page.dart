part of 'desktop_shell_screen_v2.dart';

class DesktopBorrowPage extends StatelessWidget {
  const DesktopBorrowPage({
    super.key,
    required this.pairingSession,
    required this.onBorrow,
    required this.role,
  });

  final PairingSession? pairingSession;
  final VoidCallback? onBorrow;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        const DesktopSectionHeader(
          title: 'Borrow',
          subtitle: 'Borrow items using the desktop camera or a paired phone scanner.',
        ),
        const SizedBox(height: 18),
        DesktopPanel(
          title: 'Borrow actions',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Choose how to start the borrow queue.'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  SizedBox(
                    width: 240,
                    child: FilledButton.icon(
                      onPressed: onBorrow,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan with PC camera'),
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: OutlinedButton.icon(
                      onPressed: pairingSession == null ? null : onBorrow,
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
              'This account can monitor and review records, but cannot borrow items. Use an operator or admin account at the equipment-room desk for transactions.',
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
