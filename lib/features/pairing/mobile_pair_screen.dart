import 'dart:async';

import 'package:flutter/material.dart';

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
        _statusText = 'Connected to equipment-room PC session.';
      });
      _startPolling();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Session code not found.';
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
        _statusText = 'That QR is not a desktop pairing QR.';
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
                    ? 'Return item queued on desktop. Keep scanning or switch back to the desktop to complete the return.'
                    : _selectedMode == _PairActionMode.registerItem
                        ? 'New item QR sent to desktop. Complete the item registration there.'
                        : 'Borrow item queued on desktop. Keep scanning or switch back to the desktop to complete the borrow.';
              });
              return true;
            } catch (_) {
              if (!mounted) return false;
              setState(() {
                _statusText = 'Failed to send scan to the desktop session.';
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
            ? 'Return mode sent to desktop. The web view should open the return queue shortly.'
            : mode == _PairActionMode.registerItem
                ? 'Register-item mode sent to desktop. The web view should open the new item form after the next scan.'
                : 'Borrow mode sent to desktop. The web view should open the borrow queue shortly.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Failed to send the selected mode to the desktop session.';
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
        _statusText = 'Phone disconnected from the desktop session.';
      });
      _poller?.cancel();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Failed to disconnect from the desktop session.';
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
      appBar: AppBar(title: const Text('Pair scanner')),
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
                const Text(
                  'Use phone as a scanner',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The phone can scan, but it cannot borrow or return by itself. A PC session in the equipment room must approve the action.',
                  style: TextStyle(height: 1.5, color: Color(0xFFF0ECFF)),
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
                    'Signed in as ${widget.currentUser.name}',
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
                  label: const Text('Scan desktop QR'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Fallback: enter the desktop pair code manually if the camera cannot scan the QR.',
                  style: TextStyle(height: 1.5, color: Color(0xFFF0ECFF)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _sessionController,
                  style: const TextStyle(color: Color(0xFF183A37), fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: 'Enter pairing code from PC',
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
                  child: const Text('Connect to PC session'),
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
                  ? 'Sending scan...'
                  : _selectedMode == _PairActionMode.returnItem
                      ? 'Scan item for return'
                  : _selectedMode == _PairActionMode.borrow
                          ? 'Scan item for borrow'
                          : _selectedMode == _PairActionMode.registerItem
                              ? 'Scan QR for new item'
                              : 'Choose borrow, return, or register first',
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
            label: const Text('Refresh pairing status'),
          ),
          if (_isConnected) ...<Widget>[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Disconnect phone'),
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
        return 'Waiting for desktop approval';
      case PairingSessionStatus.connected:
        return 'Ready to scan';
      case PairingSessionStatus.scanned:
        return 'Scan sent to desktop';
      case PairingSessionStatus.idle:
        return 'Idle';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Current pairing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text('Pair code: ${session.code}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Status: $_statusLabel'),
          const SizedBox(height: 8),
          Text(
            session.connectedDeviceName == null
                ? 'Desktop has not reported a device yet.'
                : 'Connected as: ${session.connectedDeviceName}',
          ),
          const SizedBox(height: 8),
          Text(
            session.lastScannedQr == null || session.lastScannedQr!.isEmpty
                ? 'No QR has been sent from this phone yet.'
                : 'Latest QR sent: ${session.lastScannedQr}',
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
        border: Border.all(color: const Color(0xFFE3E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Choose action',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the action before scanning so the desktop can place the QR into the right borrow, return, or register flow.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: ChoiceChip(
                  label: const Text('Borrow'),
                  selected: selectedMode == _PairActionMode.borrow,
                  onSelected: isUpdating ? null : (_) => onSelected(_PairActionMode.borrow),
                  selectedColor: const Color(0xFF5B39EA),
                  labelStyle: TextStyle(
                    color: selectedMode == _PairActionMode.borrow ? Colors.white : const Color(0xFF183A37),
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Return'),
                  selected: selectedMode == _PairActionMode.returnItem,
                  onSelected: isUpdating ? null : (_) => onSelected(_PairActionMode.returnItem),
                  selectedColor: const Color(0xFFE58F2A),
                  labelStyle: const TextStyle(
                    color: Color(0xFF183A37),
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide.none,
                  backgroundColor: const Color(0xFFF4F6FB),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Register'),
                  selected: selectedMode == _PairActionMode.registerItem,
                  onSelected: isUpdating ? null : (_) => onSelected(_PairActionMode.registerItem),
                  selectedColor: const Color(0xFF16C098),
                  labelStyle: TextStyle(
                    color: selectedMode == _PairActionMode.registerItem ? Colors.white : const Color(0xFF183A37),
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide.none,
                  backgroundColor: const Color(0xFFF4F6FB),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
