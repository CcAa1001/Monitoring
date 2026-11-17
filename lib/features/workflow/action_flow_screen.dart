import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/inventory_repository.dart';
import '../../models/allowed_location.dart';
import '../../models/app_user.dart';
import '../../models/item.dart';
import '../../models/pairing_session.dart';
import '../scan/scan_screen.dart';

part 'action_flow_screen_widgets.dart';

enum WorkflowMode {
  borrow,
  returnItem,
}

class ActionFlowScreen extends StatefulWidget {
  const ActionFlowScreen({
    super.key,
    required this.repository,
    required this.mode,
    this.pairingSession,
    this.desktopOnly = false,
    this.currentUser,
  });

  final InventoryRepository repository;
  final WorkflowMode mode;
  final PairingSession? pairingSession;
  final bool desktopOnly;
  final AppUser? currentUser;

  @override
  State<ActionFlowScreen> createState() => _ActionFlowScreenState();
}

class _ActionFlowScreenState extends State<ActionFlowScreen> {
  final TextEditingController _actorController = TextEditingController();

  Item? _scannedItem;
  String? _selectedLocation;
  bool _isSubmitting = false;
  bool _isRefreshingPair = false;
  late Future<List<AllowedLocation>> _locationsFuture;
  late Future<List<AppUser>> _usersFuture;
  PairingSession? _livePairingSession;
  Timer? _pairingPoller;

  bool get _isBorrow => widget.mode == WorkflowMode.borrow;
  String get _screenTitle => _isBorrow ? 'Pinjam barang' : 'Kembalikan barang';
  String get _locationTitle => _isBorrow ? 'Pilih line tujuan' : 'Pilih lokasi rak';
  String get _actorLabel => _isBorrow ? 'Nama peminjam' : 'Nama pengembali';
  String get _submitLabel => _isBorrow ? 'Konfirmasi pinjam' : 'Konfirmasi kembali';
  String get _actionLabel => _isBorrow ? 'peminjaman' : 'pengembalian';
  String? get _actorName {
    final value = _actorController.text.trim();
    return value.isEmpty ? null : value;
  }

  bool get _hasValidStateForAction {
    final item = _scannedItem;
    if (item == null) return false;
    if (_isBorrow) {
      return item.status == ItemStatus.available;
    }
    return item.status == ItemStatus.borrowed;
  }

  bool get _canSubmit {
    return !_isSubmitting &&
        _scannedItem != null &&
        _actorName != null &&
        _selectedLocation != null &&
        _hasValidStateForAction;
  }

  String get _submitHelperText {
    if (_scannedItem == null) {
      return 'Pindai barang terlebih dahulu.';
    }
    if (!_hasValidStateForAction) {
      return _isBorrow
          ? 'Barang ini sedang dipinjam, sehingga tidak dapat dipinjam lagi.'
          : 'Barang ini sudah berada di ruang peralatan.';
    }
    if (_actorName == null) {
      return 'Pilih atau ketik nama ${_isBorrow ? 'peminjam' : 'pengembali'}.';
    }
    if (_selectedLocation == null) {
      return _isBorrow ? 'Pilih line tujuan.' : 'Pilih lokasi rak.';
    }
    return 'Siap menyimpan catatan $_actionLabel ini.';
  }

  @override
  void initState() {
    super.initState();
    _livePairingSession = widget.pairingSession;
    _actorController.text = widget.currentUser?.name ?? '';
    _locationsFuture = _loadLocations();
    _usersFuture = _loadUsers();
    _startPairingPolling();
  }

  Future<List<AllowedLocation>> _loadLocations() async {
    final locations = await widget.repository.getAllowedLocations();
    return locations.where((location) {
      if (!location.isActive) return false;
      return _isBorrow ? location.type == LocationType.line : location.type == LocationType.rack;
    }).toList();
  }

  Future<List<AppUser>> _loadUsers() async {
    final users = await widget.repository.getUsers();
    final activeUsers = users.where((user) => user.isActive).toList();
    activeUsers.sort((left, right) {
      if (widget.currentUser != null) {
        if (left.id == widget.currentUser!.id) return -1;
        if (right.id == widget.currentUser!.id) return 1;
      }
      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });
    return activeUsers;
  }

  @override
  void dispose() {
    _pairingPoller?.cancel();
    _actorController.dispose();
    super.dispose();
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
    if (code == null || code.isEmpty) return;
    if (_isRefreshingPair) return;

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
      setState(() {
        _livePairingSession = session;
      });
    } finally {
      _isRefreshingPair = false;
      if (showLoader && mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _consumePhoneScan(String qrCode) async {
    final item = await widget.repository.findItemByQr(qrCode);
    if (!mounted) return;

    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pindaian dari ponsel tersambung tidak ditemukan di sistem.')),
      );
      return;
    }

    setState(() {
      _scannedItem = item;
      _selectedLocation = null;
    });
    _applyActorSuggestion(item);

    final code = _livePairingSession?.code;
    if (code != null && code.isNotEmpty) {
      final clearedSession = await widget.repository.consumePairingScan(
        sessionCode: code,
        qrCode: item.qrCode,
      );
      if (!mounted) return;
      setState(() {
        _livePairingSession = clearedSession;
      });
    }
  }

  Future<void> _scanItem() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await _refreshPairingSession(showLoader: false);
    final pairedScan = _livePairingSession?.lastScannedQr;
    if (pairedScan != null && pairedScan.isNotEmpty) {
      await _consumePhoneScan(pairedScan);
      return;
    }

    final qrCode = await navigator.push<String>(
      MaterialPageRoute<String>(
        builder: (_) => const ScanScreen(),
      ),
    );

    if (qrCode == null || !context.mounted) return;

    final item = await widget.repository.findItemByQr(qrCode);
    if (!context.mounted) return;

    if (item == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Kode QR tidak ditemukan di sistem.')),
      );
      return;
    }

    setState(() {
      _scannedItem = item;
      _selectedLocation = null;
    });
    _applyActorSuggestion(item);
  }

  void _applyActorSuggestion(Item item) {
    if (_actorController.text.trim().isNotEmpty) return;

    if (!_isBorrow && item.lastBorrowerName != null && item.lastBorrowerName!.trim().isNotEmpty) {
      _actorController.text = item.lastBorrowerName!.trim();
      return;
    }

    if (widget.currentUser != null) {
      _actorController.text = widget.currentUser!.name;
    }
  }

  Future<bool> _confirmSubmission({
    required Item item,
    required String actor,
    required String location,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBorrow ? 'Konfirmasi catatan peminjaman' : 'Konfirmasi catatan pengembalian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tinjau transaksi sebelum menyimpannya ke log pergerakan.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Barang', value: item.name),
            _SummaryRow(label: 'QR', value: item.qrCode),
            _SummaryRow(label: _isBorrow ? 'Peminjam' : 'Pengembali', value: actor),
            _SummaryRow(
              label: _isBorrow ? 'Line tujuan' : 'Lokasi rak',
              value: location,
            ),
            _SummaryRow(
              label: 'Status saat ini',
              value: item.status == ItemStatus.available ? 'Tersedia' : 'Dipinjam',
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_submitLabel),
          ),
        ],
      ),
    );

    return confirmed == true;
  }

  Future<void> _submit() async {
    final item = _scannedItem;
    final actor = _actorName;
    final location = _selectedLocation;

    if (item == null || actor == null || location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi pindaian, nama, dan lokasi terlebih dahulu.')),
      );
      return;
    }

    if (_isBorrow && item.status == ItemStatus.borrowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang ini sedang dipinjam dan tidak dapat dipinjam lagi.')),
      );
      return;
    }

    if (!_isBorrow && item.status == ItemStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang ini sudah berada di ruang peralatan.')),
      );
      return;
    }

    final confirmed = await _confirmSubmission(
      item: item,
      actor: actor,
      location: location,
    );
    if (!confirmed) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isBorrow) {
        await widget.repository.borrowItem(
          item: item,
          borrowerName: actor,
          destinationLine: location,
        );
      } else {
        await widget.repository.returnItem(
          item: item,
          returnerName: actor,
          rackLocation: location,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} berhasil ${_isBorrow ? 'dipinjam' : 'dikembalikan'}.'),
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          children: <Widget>[
            _FlowBanner(isBorrow: _isBorrow),
            if (widget.desktopOnly) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.pairingSession == null
                      ? 'Transaksi ini dikonfirmasi di PC ruang peralatan. Anda dapat memindai langsung di komputer ini, atau membuat sesi sambungan ponsel dari dasbor.'
                      : 'Transaksi ini tetap dikonfirmasi di PC ruang peralatan. Jika ponsel tersambung sudah memindai kode QR, tombol pindai akan memakai QR tersebut terlebih dahulu.',
                  style: const TextStyle(
                    color: Color(0xFF183A37),
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_livePairingSession != null) ...<Widget>[
                const SizedBox(height: 12),
                _PairingStatusCard(
                  session: _livePairingSession!,
                  isRefreshing: _isRefreshingPair,
                  onRefresh: () => _refreshPairingSession(),
                ),
              ],
            ],
            const SizedBox(height: 18),
            _StepCard(
              number: '1',
              title: 'Pindai QR barang',
              subtitle: 'Pemindaian dilakukan pertama agar sistem selalu tahu barang mana yang berpindah.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _scanItem,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(_scannedItem == null ? 'Pindai sekarang' : 'Pindai ulang'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: const Color(0xFF5B39EA),
                    ),
                  ),
                  if (_scannedItem != null) ...<Widget>[
                    const SizedBox(height: 14),
                    _ScannedItemCard(item: _scannedItem!),
                    const SizedBox(height: 12),
                    _ReadinessNotice(
                      isBorrow: _isBorrow,
                      item: _scannedItem!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _StepCard(
              number: '2',
              title: _actorLabel,
              subtitle: 'Gunakan nama yang disarankan bila memungkinkan agar pencatatan tetap cepat dan konsisten.',
              child: FutureBuilder<List<AppUser>>(
                future: _usersFuture,
                builder: (context, snapshot) {
                  final users = snapshot.data ?? const <AppUser>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (users.isNotEmpty) ...<Widget>[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: users.map((user) {
                            final selected = _actorController.text.trim().toLowerCase() == user.name.toLowerCase();
                            return ChoiceChip(
                              label: Text(user.name),
                              selected: selected,
                              avatar: CircleAvatar(
                                backgroundColor: selected ? Colors.white : const Color(0xFFEDEBFF),
                                child: Text(
                                  user.name.isEmpty ? '?' : user.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF5B39EA),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _actorController.text = user.name;
                                });
                              },
                              labelStyle: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : const Color(0xFF183A37),
                              ),
                              selectedColor: const Color(0xFF5B39EA),
                              backgroundColor: const Color(0xFFF2F3FA),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: _actorController,
                        textInputAction: TextInputAction.done,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: _isBorrow ? 'Contoh: Budi' : 'Contoh: Sinta',
                          helperText: widget.currentUser == null
                              ? 'Isian manual tetap diperbolehkan jika nama tidak ada di daftar.'
                              : 'Masuk sebagai ${widget.currentUser!.name}. Anda dapat tetap memakai nama itu atau menggantinya.',
                          filled: true,
                          fillColor: const Color(0xFFF7F8F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _StepCard(
              number: '3',
              title: _locationTitle,
              subtitle: _isBorrow
                  ? 'Operator memilih line tujuan dari daftar tetap, bukan dengan mengetik.'
                  : 'Pengembalian wajib menentukan rak yang tepat agar orang berikutnya dapat menemukannya dengan cepat.',
              child: FutureBuilder<List<AllowedLocation>>(
                future: _locationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final locations = snapshot.data ?? <AllowedLocation>[];
                  if (locations.isEmpty) {
                    return Text(
                      _isBorrow
                          ? 'Belum ada line tujuan yang aktif.'
                          : 'Belum ada lokasi rak yang aktif.',
                      style: const TextStyle(
                        color: Color(0xFF5D7470),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: locations.map((location) {
                      final selected = location.code == _selectedLocation;
                      return ChoiceChip(
                        label: Text(location.code),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _selectedLocation = location.code;
                          });
                        },
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : const Color(0xFF183A37),
                        ),
                        selectedColor: const Color(0xFF5B39EA),
                        backgroundColor: const Color(0xFFF2F3FA),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            _SubmitPreview(
              title: _isBorrow ? 'Sebelum konfirmasi' : 'Siap konfirmasi pengembalian',
              message: _submitHelperText,
              isReady: _canSubmit,
              item: _scannedItem,
              actorName: _actorName,
              selectedLocation: _selectedLocation,
              isBorrow: _isBorrow,
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5B39EA),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(58),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      _submitLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
