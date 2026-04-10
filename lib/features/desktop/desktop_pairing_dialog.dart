part of 'desktop_shell_screen_v2.dart';

class DesktopPairingDialog extends StatefulWidget {
  const DesktopPairingDialog({
    super.key,
    required this.repository,
    required this.initialSession,
    required this.payloadBuilder,
    required this.onSessionChanged,
  });

  final InventoryRepository repository;
  final PairingSession initialSession;
  final String Function(String code) payloadBuilder;
  final ValueChanged<PairingSession> onSessionChanged;

  @override
  State<DesktopPairingDialog> createState() => _DesktopPairingDialogState();
}

class _DesktopPairingDialogState extends State<DesktopPairingDialog> {
  late PairingSession _session;
  Timer? _poller;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _poller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  String get _statusLabel {
    switch (_session.status) {
      case PairingSessionStatus.waitingForPhone:
        return 'Waiting for phone scan';
      case PairingSessionStatus.connected:
        return 'Phone connected';
      case PairingSessionStatus.scanned:
        return 'Item scan received';
      case PairingSessionStatus.idle:
        return 'Idle';
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final refreshed = await widget.repository.getPairingSession(_session.code);
      if (!mounted || refreshed == null) return;
      setState(() {
        _session = refreshed;
      });
      widget.onSessionChanged(refreshed);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _disconnect() async {
    final cleared = await widget.repository.disconnectPairingSession(
      sessionCode: _session.code,
    );
    if (!mounted) return;
    setState(() {
      _session = cleared;
    });
    widget.onSessionChanged(cleared);
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.payloadBuilder(_session.code);
    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Pair Phone Scanner',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Scan this QR in the mobile app. After that, the phone can keep sending item scans to this desktop session.',
                          style: TextStyle(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F5)),
                      ),
                      child: Column(
                        children: <Widget>[
                          QrImageView(
                            data: payload,
                            version: QrVersions.auto,
                            size: 260,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF1F2533),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF1F2533),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _session.code,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.6),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Fallback: if the phone camera cannot scan the desktop QR, the operator can still type this code manually.',
                            textAlign: TextAlign.center,
                            style: TextStyle(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _DesktopPairStep(number: '1', text: 'Open the mobile app and tap Scan desktop QR.'),
                        const SizedBox(height: 12),
                        const _DesktopPairStep(number: '2', text: 'Point the phone camera at this QR code.'),
                        const SizedBox(height: 12),
                        const _DesktopPairStep(number: '3', text: 'Once connected, keep the phone on the scanner screen and scan item QR codes.'),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Status: $_statusLabel',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              Text('Connected phone: ${_session.connectedDeviceName ?? 'Not connected yet'}'),
                              const SizedBox(height: 8),
                              Text('Last scan received: ${_session.lastScannedQr ?? '-'}'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh status'),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: (_session.connectedDeviceName ?? '').isEmpty ? null : _disconnect,
                          icon: const Icon(Icons.link_off_rounded),
                          label: const Text('Unpair phone'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopPairStep extends StatelessWidget {
  const _DesktopPairStep({
    required this.number,
    required this.text,
  });

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF5B39EA),
          foregroundColor: Colors.white,
          child: Text(number, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(height: 1.5, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
