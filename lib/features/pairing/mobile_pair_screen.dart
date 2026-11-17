import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_language.dart';
import '../../data/inventory_repository.dart';
import '../../models/app_user.dart';
import '../../models/pairing_session.dart';
import '../scan/scan_screen.dart';

enum _PairActionMode {
  borrow,
  returnItem,
  registerItem,
}

class MobilePairScreen extends StatefulWidget {
  const MobilePairScreen({
    super.key,
    required this.repository,
    required this.currentUser,
  });

  final InventoryRepository repository;
  final AppUser currentUser;

  @override
  State<MobilePairScreen> createState() => _MobilePairScreenState();
}

class _MobilePairScreenState extends State<MobilePairScreen> {
  final TextEditingController _sessionController = TextEditingController();
  bool _isConnected = false;
  bool _isBusy = false;
  bool _isSettingMode = false;
  String? _statusText;
  PairingSession? _session;
  Timer? _poller;
  _PairActionMode? _selectedMode;

  String? _extractPairCode(String rawValue) {
    final uri = Uri.tryParse(rawValue);
    final code = uri?.queryParameters['code'];
    if (uri?.scheme == 'factory-monitoring' && uri?.host == 'pair' && code != null && code.isNotEmpty) {
      return code;
    }

    return null;
  }

  @override
  void dispose() {
    _poller?.cancel();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final code = _sessionController.text.trim();
    if (code.isEmpty) return;

    try {
      final session = await widget.repository.connectPhoneToSession(
        sessionCode: code,
        deviceName: widget.currentUser.name,
      );

      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _session = session;
        _selectedMode = _mapFromSessionMode(session.activeMode);
        _statusText = tr('Tersambung ke sesi PC ruang peralatan.');
      });
      _startPolling();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusText = tr('Kode sesi tidak ditemukan.');
      });
    }
  }

  Future<void> _connectByDesktopQr() async {
    final rawValue = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const ScanScreen(),
      ),
    );

    if (rawValue == null || !mounted) return;
    final code = _extractPairCode(rawValue);
    if (code == null) {
      setState(() {
        _statusText = tr('QR tersebut bukan QR sambungan desktop.');
      });
      return;
    }

    _sessionController.text = code;
    await _connect();
  }

  void _startPolling() {
    _poller?.cancel();
    _poller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshSession(),
    );
  }

  Future<void> _refreshSession() async {
    final code = _sessionController.text.trim();
    if (!_isConnected || code.isEmpty) return;

    try {
      final session = await widget.repository.getPairingSession(code);
      if (!mounted || session == null) return;
      setState(() {
        _session = session;
        _isConnected = session.connectedDeviceName != null && session.connectedDeviceName!.isNotEmpty;
        _selectedMode = _mapFromSessionMode(session.activeMode) ?? _selectedMode;
      });
    } catch (_) {
      // Keep the current view stable if the session refresh fails momentarily.
    }
  }

  Future<void> _scanForPc() async {
    final code = _sessionController.text.trim();
    if (!_isConnected || code.isEmpty) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ScanScreen(
          allowContinuous: true,
          onDetected: (qrCode) async {
            setState(() {
              _isBusy = true;
            });

            try {
              final session = await widget.repository.submitPhoneScan(
                sessionCode: code,
                qrCode: qrCode,
                mode: _selectedMode == _PairActionMode.returnItem
                    ? PairActionMode.returnItem
                    : _selectedMode == _PairActionMode.registerItem
                        ? PairActionMode.registerItem
                        : PairActionMode.borrow,
              );

              if (!mounted) return false;
              setState(() {
                _session = session;
                _statusText = _selectedMode == _PairActionMode.returnItem
                    ? tr('Barang kembali masuk antrean di desktop. Lanjutkan memindai atau beralih ke desktop untuk menyelesaikan pengembalian.')
                    : _selectedMode == _PairActionMode.registerItem
                        ? tr('QR barang baru dikirim ke desktop. Selesaikan registrasi barang di sana.')
                        : tr('Barang pinjam masuk antrean di desktop. Lanjutkan memindai atau beralih ke desktop untuk menyelesaikan peminjaman.');
              });
              return true;
            } catch (_) {
              if (!mounted) return false;
              setState(() {
                _statusText = tr('Gagal mengirim pindaian ke sesi desktop.');
              });
              return false;
            } finally {
              if (mounted) {
                setState(() {
                  _isBusy = false;
                });
              }
            }
          },
        ),
      ),
    );
  }

  Future<void> _selectMode(_PairActionMode mode) async {
    if (!_isConnected || _session == null) {
      setState(() {
        _selectedMode = mode;
      });
      return;
    }

    setState(() {
      _isSettingMode = true;
      _selectedMode = mode;
    });

    try {
      final updatedSession = await widget.repository.setPairingMode(
        sessionCode: _session!.code,
        mode: mode == _PairActionMode.borrow
            ? PairActionMode.borrow
            : mode == _PairActionMode.returnItem
                ? PairActionMode.returnItem
                : PairActionMode.registerItem,
      );

      if (!mounted) return;
      setState(() {
        _session = updatedSession;
        _statusText = mode == _PairActionMode.returnItem
            ? tr('Mode kembali dikirim ke desktop. Antrean pengembalian akan segera terbuka di desktop.')
            : mode == _PairActionMode.registerItem
                ? tr('Mode daftar barang dikirim ke desktop. Formulir barang baru akan terbuka di desktop setelah pindaian berikutnya.')
                : tr('Mode pinjam dikirim ke desktop. Antrean peminjaman akan segera terbuka di desktop.');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusText = tr('Gagal mengirim mode yang dipilih ke sesi desktop.');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSettingMode = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    final session = _session;
    if (!_isConnected || session == null) return;

    try {
      final cleared = await widget.repository.disconnectPairingSession(
        sessionCode: session.code,
      );
      if (!mounted) return;
      setState(() {
        _session = cleared;
        _isConnected = false;
        _selectedMode = null;
        _statusText = tr('Ponsel terputus dari sesi desktop.');
      });
      _poller?.cancel();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusText = tr('Gagal memutuskan sambungan dari sesi desktop.');
      });
    }
  }

  _PairActionMode? _mapFromSessionMode(PairActionMode? mode) {
    switch (mode) {
      case PairActionMode.borrow:
        return _PairActionMode.borrow;
      case PairActionMode.returnItem:
        return _PairActionMode.returnItem;
      case PairActionMode.registerItem:
        return _PairActionMode.registerItem;
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Sambungkan pemindai'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF6D52F5), Color(0xFF5B39EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tr('Gunakan ponsel sebagai pemindai'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('Ponsel dapat memindai, tetapi tidak dapat meminjam atau mengembalikan sendiri. Sesi PC di ruang peralatan harus menyetujui aksinya.'),
                  style: const TextStyle(height: 1.5, color: Color(0xFFF0ECFF)),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: Text(
                    tr('Masuk sebagai {name}', {'name': widget.currentUser.name}),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _connectByDesktopQr,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE58F2A),
                    foregroundColor: const Color(0xFF183A37),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(tr('Pindai QR desktop')),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('Alternatif: masukkan kode sambungan desktop secara manual jika kamera tidak dapat memindai QR.'),
                  style: const TextStyle(height: 1.5, color: Color(0xFFF0ECFF)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sessionController,
                  style: const TextStyle(color: Color(0xFF183A37), fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: tr('Masukkan kode sambungan dari PC'),
                    hintStyle: const TextStyle(color: Color(0xFF6A738A)),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _connect,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5B39EA),
                  ),
                  child: Text(tr('Sambungkan ke sesi PC')),
                ),
                if (_statusText != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _statusText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_session != null) ...<Widget>[
            const SizedBox(height: 16),
            _PhoneSessionCard(session: _session!),
          ],
          const SizedBox(height: 16),
          if (_isConnected) ...<Widget>[
            _ModePicker(
              selectedMode: _selectedMode,
              isUpdating: _isSettingMode,
              onSelected: _selectMode,
            ),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: _isConnected && !_isBusy && _selectedMode != null ? _scanForPc : null,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(
              _isBusy
                  ? tr('Mengirim pindaian...')
                  : _selectedMode == _PairActionMode.returnItem
                      ? tr('Pindai barang untuk dikembalikan')
                  : _selectedMode == _PairActionMode.borrow
                          ? tr('Pindai barang untuk dipinjam')
                          : _selectedMode == _PairActionMode.registerItem
                              ? tr('Pindai QR untuk barang baru')
                              : tr('Pilih pinjam, kembali, atau daftar terlebih dahulu'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: const Color(0xFFE58F2A),
              foregroundColor: const Color(0xFF183A37),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isConnected ? _refreshSession : null,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(tr('Perbarui status sambungan')),
          ),
          if (_isConnected) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off_rounded),
              label: Text(tr('Putuskan ponsel')),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhoneSessionCard extends StatelessWidget {
  const _PhoneSessionCard({
    required this.session,
  });

  final PairingSession session;

  String get _statusLabel {
    switch (session.status) {
      case PairingSessionStatus.waitingForPhone:
        return tr('Menunggu persetujuan desktop');
      case PairingSessionStatus.connected:
        return tr('Siap memindai');
      case PairingSessionStatus.scanned:
        return tr('Pindaian terkirim ke desktop');
      case PairingSessionStatus.idle:
        return tr('Siaga');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            tr('Sambungan saat ini'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(tr('Kode sambungan: {code}', {'code': session.code}), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Status: $_statusLabel'),
          const SizedBox(height: 8),
          Text(
            session.connectedDeviceName == null
                ? tr('Desktop belum melaporkan perangkat.')
                : tr('Tersambung sebagai: {device}', {'device': session.connectedDeviceName}),
          ),
          const SizedBox(height: 8),
          Text(
            session.lastScannedQr == null || session.lastScannedQr!.isEmpty
                ? tr('Belum ada QR yang dikirim dari ponsel ini.')
                : tr('QR terakhir dikirim: {qr}', {'qr': session.lastScannedQr}),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ModePicker extends StatelessWidget {
  const _ModePicker({
    required this.selectedMode,
    required this.isUpdating,
    required this.onSelected,
  });

  final _PairActionMode? selectedMode;
  final bool isUpdating;
  final ValueChanged<_PairActionMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            tr('Pilih aksi'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            tr('Pilih aksi sebelum memindai agar desktop dapat menempatkan QR ke alur pinjam, kembali, atau daftar yang tepat.'),
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: ChoiceChip(
                  label: Text(tr('Pinjam')),
                  selected: selectedMode == _PairActionMode.borrow,
                  onSelected: isUpdating ? null : (_) => onSelected(_PairActionMode.borrow),
                  selectedColor: const Color(0xFF5B39EA),
                  labelStyle: TextStyle(
                    color: selectedMode == _PairActionMode.borrow ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide.none,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: Text(tr('Kembali')),
                  selected: selectedMode == _PairActionMode.returnItem,
                  onSelected: isUpdating ? null : (_) => onSelected(_PairActionMode.returnItem),
                  selectedColor: const Color(0xFFE58F2A),
                  labelStyle: TextStyle(
                    color: selectedMode == _PairActionMode.returnItem
                        ? const Color(0xFF183A37)
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide.none,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: Text(tr('Daftar')),
                  selected: selectedMode == _PairActionMode.registerItem,
                  onSelected: isUpdating ? null : (_) => onSelected(_PairActionMode.registerItem),
                  selectedColor: const Color(0xFF16C098),
                  labelStyle: TextStyle(
                    color: selectedMode == _PairActionMode.registerItem ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide.none,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
            ],
          ),
          if (isUpdating) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
