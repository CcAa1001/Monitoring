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
        _DesktopTransactionHero(
          accentColors: const <Color>[Color(0xFF6D52F5), Color(0xFF4E35D8)],
          badge: 'Borrow workspace',
          title: 'Borrow items with a cleaner queue and clearer scanning choices.',
          description:
              'Start from the desk camera or a paired roaming phone, then send every scan into one structured borrow flow before choosing the destination line.',
          primaryLabel: 'Open borrow queue',
          primaryIcon: Icons.call_made_rounded,
          primaryAction: onBorrow,
          secondaryLabel: pairingSession == null ? 'Pair a phone on dashboard' : 'Phone is paired and ready',
          secondaryIcon: Icons.phonelink_ring_rounded,
          statusTitle: 'Borrow station',
          statusValue: pairingSession == null ? 'Desk scanner only' : 'Phone-assisted',
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
                    const _DesktopTransactionPanelHeader(
                      title: 'Choose how items enter the queue',
                      caption: 'Both paths lead into the same borrow queue, so the desk can keep one clean review and submit step.',
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DesktopActionCard(
                            title: 'Desk scanner',
                            description: 'Best when items are handed directly to the equipment room. Fast, direct, and ideal for a fixed operator.',
                            icon: Icons.qr_code_scanner_rounded,
                            buttonLabel: 'Scan on this PC',
                            onTap: onBorrow,
                            primary: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _DesktopActionCard(
                            title: 'Paired phone scanner',
                            description: pairingSession == null
                                ? 'Pair a phone first if you want roaming scans that still land in the same borrow queue.'
                                : 'Phone ${pairingSession!.connectedDeviceName ?? 'scanner'} can move around the room and keep sending borrow scans back here.',
                            icon: Icons.smartphone_rounded,
                            buttonLabel: pairingSession == null ? 'Not paired yet' : 'Use paired phone',
                            onTap: pairingSession == null ? null : onBorrow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _DesktopProcessStrip(
                      steps: <String>[
                        'Scan item QR',
                        'Review each row in queue',
                        'Choose borrower line',
                        'Confirm the borrow movement',
                      ],
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
                    const _DesktopTransactionPanelHeader(
                      title: 'Pairing snapshot',
                      caption: 'A paired phone can keep scanning while the desk reviews and submits the queue.',
                    ),
                    const SizedBox(height: 18),
                    _DesktopPairingSummary(
                      pairingSession: pairingSession,
                      emptyMessage: 'No phone is paired right now. Start pairing from the dashboard to show the desktop QR and connect a roaming scanner.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (role == UserRole.viewer)
          const DesktopPanel(
            child: Text(
              'This account can monitor and review borrow activity, but cannot start a borrow queue. Use an operator or admin account for transactions.',
            ),
          ),
      ],
    );
  }
}
