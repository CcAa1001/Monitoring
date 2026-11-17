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
        return tr('Menunggu pindaian ponsel');
      case PairingSessionStatus.connected:
        return tr('Ponsel tersambung');
      case PairingSessionStatus.scanned:
        return tr('Pindaian barang diterima');
      case PairingSessionStatus.idle:
        return tr('Siaga');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          tr('Sambungkan Pemindai Ponsel'),
                          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tr('Pindai QR ini di aplikasi ponsel. Setelah itu, ponsel dapat terus mengirim pindaian barang ke sesi desktop ini.'),
                          style: const TextStyle(height: 1.5),
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
                        color: isDark ? const Color(0xFF111726) : const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? const Color(0xFF28314B) : const Color(0xFFE2E8F5),
                        ),
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
                          Text(
                            tr('Alternatif: jika kamera ponsel tidak dapat memindai QR desktop, operator tetap dapat mengetik kode ini secara manual.'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(height: 1.5),
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
                        _DesktopPairStep(number: '1', text: tr('Buka aplikasi ponsel dan ketuk Pindai QR desktop.')),
                        const SizedBox(height: 12),
                        _DesktopPairStep(number: '2', text: tr('Arahkan kamera ponsel ke kode QR ini.')),
                        const SizedBox(height: 12),
                        _DesktopPairStep(number: '3', text: tr('Setelah tersambung, biarkan ponsel di layar pemindai dan pindai kode QR barang.')),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF111726) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF28314B) : Colors.transparent,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Status: $_statusLabel',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              Text(tr('Ponsel tersambung: {device}', {'device': _session.connectedDeviceName ?? tr('Belum tersambung')})),
                              const SizedBox(height: 8),
                              Text(tr('Pindaian terakhir diterima: {qr}', {'qr': _session.lastScannedQr ?? '-'})),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(tr('Perbarui status')),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: (_session.connectedDeviceName ?? '').isEmpty ? null : _disconnect,
                          icon: const Icon(Icons.link_off_rounded),
                          label: Text(tr('Putuskan ponsel')),
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
