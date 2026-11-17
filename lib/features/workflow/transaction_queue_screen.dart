import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_language.dart';
import '../../data/inventory_repository.dart';
import '../../models/allowed_location.dart';
import '../../models/app_user.dart';
import '../../models/item.dart';
import '../../models/pairing_session.dart';
import '../../theme/status_colors.dart';
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
  DateTime? _borrowExpectedReturnAt;

  bool get _isBorrow => widget.mode == WorkflowMode.borrow;
  String get _screenTitle => _isBorrow ? tr('Pinjam barang') : tr('Kembalikan barang');
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
        SnackBar(content: Text(tr('{qr} sudah ada di antrean ini.', {'qr': item.qrCode}))),
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
        SnackBar(content: Text(tr('Kode QR tidak ditemukan di sistem.'))),
      );
      return;
    }

    _addDraft(item, fromPairing: false, actorName: widget.currentUser.name);
  }

  Future<void> _removeDraft(_QueuedItemDraft draft) async {
    final index = _drafts.indexOf(draft);
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
    });

    var restored = false;
    await ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('{name} dihapus dari antrean.', {'name': draft.item.name})),
        action: SnackBarAction(
          label: tr('Urungkan'),
          onPressed: () {
            if (!mounted) return;
            restored = true;
            final safeIndex = index < 0 ? _drafts.length : index.clamp(0, _drafts.length).toInt();
            setState(() {
              _drafts.insert(safeIndex, draft);
            });
          },
        ),
      ),
    ).closed;

    if (!restored) {
      draft.dispose();
    }
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
            expectedReturnAt: _borrowExpectedReturnAt,
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
        _borrowExpectedReturnAt = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBorrow
                ? tr('Transaksi peminjaman disimpan untuk {count} barang.', {'count': processedCount})
                : tr('Transaksi pengembalian disimpan untuk {count} barang.', {'count': processedCount}),
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('Transaksi gagal disimpan. Periksa koneksi lalu coba lagi. {error}', {'error': error})),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ---- Display-only helpers (mirror _canSubmitBorrow / _canSubmitReturn) ----

  /// 0 = Pindai aset, 1 = Pilih tujuan, 2 = Konfirmasi.
  int get _currentStep {
    if (_drafts.isEmpty) return 0;
    final destinationChosen = _isBorrow
        ? _borrowDestinationLine != null
        : _drafts.every((draft) => draft.selectedLocation != null);
    return destinationChosen ? 2 : 1;
  }

  /// Why the confirm button is disabled, or null when it is enabled.
  String? get _blockedReason {
    if (_drafts.isEmpty) return tr('Pindai minimal 1 aset untuk melanjutkan.');
    if (_isBorrow) {
      final alreadyOut = _drafts.where((draft) => draft.item.status != ItemStatus.available).length;
      if (alreadyOut > 0) return tr('{count} aset sedang dipinjam. Hapus dari antrean untuk melanjutkan.', {'count': alreadyOut});
      if (_borrowDestinationLine == null) return tr('Pilih line tujuan untuk melanjutkan.');
      return null;
    }
    final alreadyIn = _drafts.where((draft) => draft.item.status != ItemStatus.borrowed).length;
    if (alreadyIn > 0) return tr('{count} aset sudah tersedia di rak. Hapus dari antrean untuk melanjutkan.', {'count': alreadyIn});
    final missingRack = _drafts.where((draft) => draft.selectedLocation == null).length;
    if (missingRack > 0) return tr('Pilih rak tujuan untuk {count} aset lagi.', {'count': missingRack});
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _isBorrow ? _canSubmitBorrow : _canSubmitReturn;
    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: FutureBuilder<List<AllowedLocation>>(
        future: _locationsFuture,
        builder: (context, snapshot) {
          final locations = snapshot.data ?? const <AllowedLocation>[];
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _queueMaxWidth),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: <Widget>[
                  _StepIndicator(currentStep: _currentStep),
                  const SizedBox(height: 16),
                  _ScanToolbar(
                    currentUser: widget.currentUser,
                    pairingSession: _livePairingSession,
                    isRefreshingPair: _isRefreshingPair,
                    onRefreshPairing: () => _refreshPairingSession(),
                    onScanDesktop: _scanItemFromDesktop,
                  ),
                  const SizedBox(height: 16),
                  _ScannedItemsSection(
                    isBorrow: _isBorrow,
                    drafts: _drafts,
                    racks: _isBorrow ? const <AllowedLocation>[] : locations,
                    onLocationSelected: (draft, location) {
                      setState(() {
                        draft.selectedLocation = location;
                      });
                    },
                    onDescriptionChanged: () => setState(() {}),
                    onRemove: _removeDraft,
                  ),
                  if (_isBorrow) ...<Widget>[
                    const SizedBox(height: 16),
                    _BorrowDestinationCard(
                      selectedLine: _borrowDestinationLine,
                      lines: locations,
                      expectedReturnAt: _borrowExpectedReturnAt,
                      onLineSelected: (line) {
                        setState(() {
                          _borrowDestinationLine = line;
                        });
                      },
                      onDueDateSelected: (date) {
                        setState(() {
                          _borrowExpectedReturnAt = date;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _ConfirmBar(
        label: _isBorrow ? tr('Konfirmasi pinjam') : tr('Konfirmasi kembali'),
        isSubmitting: _isSubmitting,
        hint: _isSubmitting || canSubmit ? null : _blockedReason,
        onConfirm: _isSubmitting || !canSubmit ? null : _submit,
      ),
    );
  }
}

const double _queueMaxWidth = 1100;
