import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/inventory_repository.dart';
import '../../models/allowed_location.dart';
import '../../models/app_user.dart';
import '../../models/item.dart';
import '../../models/pairing_session.dart';
import '../scan/scan_screen.dart';
import 'action_flow_screen.dart';

part 'transaction_queue_screen_widgets.dart';

class TransactionQueueScreen extends StatefulWidget {
  const TransactionQueueScreen({
    super.key,
    required this.repository,
    required this.mode,
    required this.currentUser,
    this.pairingSession,
  });

  final InventoryRepository repository;
  final WorkflowMode mode;
  final AppUser currentUser;
  final PairingSession? pairingSession;

  @override
  State<TransactionQueueScreen> createState() => _TransactionQueueScreenState();
}

class _TransactionQueueScreenState extends State<TransactionQueueScreen> {
  late Future<List<AllowedLocation>> _locationsFuture;
  final List<_QueuedItemDraft> _drafts = <_QueuedItemDraft>[];
  PairingSession? _livePairingSession;
  Timer? _pairingPoller;
  bool _isRefreshingPair = false;
  bool _isSubmitting = false;
  String? _borrowDestinationLine;

  bool get _isBorrow => widget.mode == WorkflowMode.borrow;
  String get _screenTitle => _isBorrow ? 'Borrow items' : 'Return items';
  PairActionMode get _pairMode => _isBorrow ? PairActionMode.borrow : PairActionMode.returnItem;

  @override
  void initState() {
    super.initState();
    _livePairingSession = widget.pairingSession;
    _locationsFuture = _loadLocations();
    _startPairingPolling();
  }

  @override
  void dispose() {
    _pairingPoller?.cancel();
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<List<AllowedLocation>> _loadLocations() async {
    final locations = await widget.repository.getAllowedLocations();
    return locations.where((location) {
      if (!location.isActive) return false;
      return _isBorrow ? location.type == LocationType.line : location.type == LocationType.rack;
    }).toList();
  }

  void _startPairingPolling() {
    final code = widget.pairingSession?.code;
    if (code == null || code.isEmpty) return;

    _refreshPairingSession(showLoader: false);
    _pairingPoller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshPairingSession(showLoader: false),
    );
  }

  Future<void> _refreshPairingSession({bool showLoader = true}) async {
    final code = widget.pairingSession?.code;
    if (code == null || code.isEmpty || _isRefreshingPair) return;

    if (showLoader && mounted) {
      setState(() {
        _isRefreshingPair = true;
      });
    } else {
      _isRefreshingPair = true;
    }

    try {
      final session = await widget.repository.getPairingSession(code);
      if (!mounted || session == null) return;
      _livePairingSession = session;
      await _ingestPendingScans(session);
      if (mounted) {
        setState(() {});
      }
    } finally {
      _isRefreshingPair = false;
      if (showLoader && mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _ingestPendingScans(PairingSession session) async {
    final matchingEntries = session.pendingScans.where((entry) => entry.mode == _pairMode).toList();
    for (final entry in matchingEntries) {
      if (_drafts.any((draft) => draft.item.qrCode.toUpperCase() == entry.qrCode.toUpperCase())) {
        continue;
      }
      final item = await widget.repository.findItemByQr(entry.qrCode);
      if (!mounted || item == null) continue;
      _addDraft(
        item,
        fromPairing: true,
        actorName: entry.scannedBy ?? session.connectedDeviceName ?? widget.currentUser.name,
      );
    }
  }

  void _addDraft(
    Item item, {
    required bool fromPairing,
    String? actorName,
  }) {
    final alreadyExists = _drafts.any((draft) => draft.item.qrCode.toUpperCase() == item.qrCode.toUpperCase());
    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.qrCode} is already in this queue.')),
      );
      return;
    }

    setState(() {
      _drafts.add(
        _QueuedItemDraft(
          item: item,
          fromPairing: fromPairing,
          actorName: actorName ?? widget.currentUser.name,
        ),
      );
    });
  }

  Future<void> _scanItemFromDesktop() async {
    final qrCode = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const ScanScreen(),
      ),
    );

    if (qrCode == null || !mounted) return;

    final item = await widget.repository.findItemByQr(qrCode);
    if (!mounted) return;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR code not found in the system.')),
      );
      return;
    }

    _addDraft(item, fromPairing: false, actorName: widget.currentUser.name);
  }

  Future<void> _removeDraft(_QueuedItemDraft draft) async {
    if (draft.fromPairing && _livePairingSession != null) {
      await widget.repository.consumePairingScan(
        sessionCode: _livePairingSession!.code,
        qrCode: draft.item.qrCode,
      );
      await _refreshPairingSession(showLoader: false);
    }

    if (!mounted) return;
    setState(() {
      _drafts.remove(draft);
      draft.dispose();
    });
  }

  bool get _canSubmitBorrow {
    return _drafts.isNotEmpty &&
        _borrowDestinationLine != null &&
        _drafts.every((draft) => draft.item.status == ItemStatus.available);
  }

  bool get _canSubmitReturn {
    return _drafts.isNotEmpty &&
        _drafts.every((draft) => draft.item.status == ItemStatus.borrowed && draft.selectedLocation != null);
  }

  Future<void> _submit() async {
    if (_isBorrow && !_canSubmitBorrow) return;
    if (!_isBorrow && !_canSubmitReturn) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final processedCount = _drafts.length;
      for (final draft in List<_QueuedItemDraft>.from(_drafts)) {
        final description = draft.descriptionController.text.trim();
        if (_isBorrow) {
          await widget.repository.borrowItem(
            item: draft.item,
            borrowerName: draft.actorName,
            destinationLine: _borrowDestinationLine!,
            description: description.isEmpty ? null : description,
          );
        } else {
          await widget.repository.returnItem(
            item: draft.item,
            returnerName: draft.actorName,
            rackLocation: draft.selectedLocation!,
            description: description.isEmpty ? null : description,
          );
        }

        if (draft.fromPairing && _livePairingSession != null) {
          await widget.repository.consumePairingScan(
            sessionCode: _livePairingSession!.code,
            qrCode: draft.item.qrCode,
          );
        }
      }

      if (!mounted) return;

      for (final draft in _drafts) {
        draft.dispose();
      }

      setState(() {
        _drafts.clear();
        _borrowDestinationLine = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBorrow
                ? 'Borrow transaction saved for $processedCount item${processedCount == 1 ? '' : 's'}.'
                : 'Return transaction saved for $processedCount item${processedCount == 1 ? '' : 's'}.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: FutureBuilder<List<AllowedLocation>>(
        future: _locationsFuture,
        builder: (context, snapshot) {
          final locations = snapshot.data ?? const <AllowedLocation>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: <Widget>[
              _SessionBanner(
                isBorrow: _isBorrow,
                currentUser: widget.currentUser,
                pairingSession: _livePairingSession,
                isRefreshingPair: _isRefreshingPair,
                onRefreshPairing: () => _refreshPairingSession(),
              ),
              const SizedBox(height: 16),
              _ScanControlCard(
                isBorrow: _isBorrow,
                queueCount: _drafts.length,
                onScanDesktop: _scanItemFromDesktop,
              ),
              const SizedBox(height: 16),
              if (_isBorrow)
                _BorrowQueueCard(
                  drafts: _drafts,
                  selectedLine: _borrowDestinationLine,
                  lines: locations,
                  onLineSelected: (line) {
                    setState(() {
                      _borrowDestinationLine = line;
                    });
                  },
                  onDescriptionChanged: () => setState(() {}),
                  onRemove: _removeDraft,
                )
              else
                _ReturnQueueCard(
                  drafts: _drafts,
                  racks: locations,
                  onLocationSelected: (draft, location) {
                    setState(() {
                      draft.selectedLocation = location;
                    });
                  },
                  onDescriptionChanged: () => setState(() {}),
                  onRemove: _removeDraft,
                ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _isSubmitting
                    ? null
                    : _isBorrow
                        ? (_canSubmitBorrow ? _submit : null)
                        : (_canSubmitReturn ? _submit : null),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isBorrow ? 'Confirm borrow' : 'Confirm return'),
              ),
            ],
          );
        },
      ),
    );
  }
}
