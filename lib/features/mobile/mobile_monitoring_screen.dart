import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_language.dart';
import '../../data/inventory_repository.dart';
import '../../models/app_user.dart';
import '../../models/item.dart';
import '../../models/movement_record.dart';
import '../../theme/status_colors.dart';
import '../pairing/mobile_pair_screen.dart';

class MobileMonitoringScreen extends StatefulWidget {
  const MobileMonitoringScreen({
    super.key,
    required this.repository,
    required this.themeMode,
    required this.onToggleTheme,
    required this.currentUser,
    required this.onLogout,
  });

  final InventoryRepository repository;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final AppUser currentUser;
  final VoidCallback onLogout;

  @override
  State<MobileMonitoringScreen> createState() => _MobileMonitoringScreenState();
}

class _MobileMonitoringScreenState extends State<MobileMonitoringScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<_MobileData> _future;
  int _selectedIndex = 0;
  StreamSubscription<void>? _inventorySubscription;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _inventorySubscription = widget.repository.watchInventoryChanges().listen(
          (_) => _reloadSilently(),
          onError: (_) {},
        );
  }

  @override
  void dispose() {
    _inventorySubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Realtime refresh: fetch first, then swap in the completed data so the
  /// FutureBuilder keeps showing the current list instead of a spinner.
  Future<void> _reloadSilently() async {
    try {
      final data = await _load();
      if (!mounted) return;
      setState(() {
        _future = Future<_MobileData>.value(data);
      });
    } catch (_) {
      // Keep showing the last known data.
    }
  }

  Future<_MobileData> _load() async {
    final items = await widget.repository.getItems();
    final movements = await widget.repository.getRecentMovements();
    return _MobileData(items: items, movements: movements);
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _openPairing() async {
    HapticFeedback.mediumImpact();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MobilePairScreen(
          repository: widget.repository,
          currentUser: widget.currentUser,
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF6D52F5), Color(0xFF5B39EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                      child: Text(
                        widget.currentUser.name.isEmpty ? 'U' : widget.currentUser.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.currentUser.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.currentUser.badgeId} | ${widget.currentUser.role.label}',
                      style: const TextStyle(color: Color(0xFFF0ECFF), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_rounded),
                title: Text(tr('Ringkasan')),
                selected: _selectedIndex == 0,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.inventory_2_rounded),
                title: Text(tr('Barang')),
                selected: _selectedIndex == 1,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: Text(tr('Pergerakan')),
                selected: _selectedIndex == 2,
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phonelink_setup_rounded),
                title: Text(tr('Sambungkan pemindai')),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _openPairing();
                },
              ),
              ListTile(
                leading: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                title: Text(tr('Ganti tema')),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onToggleTheme();
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(tr('Bahasa')),
                trailing: Text(
                  isEnglish ? 'English' : 'Bahasa Indonesia',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: toggleAppLanguage,
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(tr('Muat ulang data')),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _refresh();
                },
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(tr('Keluar')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<_MobileData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final readyCount = data.items.where((item) => item.status == ItemStatus.available).length;
          final outCount = data.items.where((item) => item.status == ItemStatus.borrowed).length;
          final overdueCount = data.items.where((item) => item.isOverdue).length;
          final query = _searchController.text.trim().toLowerCase();
          final filteredItems = data.items.where((item) {
            if (query.isEmpty) return true;
            return item.name.toLowerCase().contains(query) ||
                item.qrCode.toLowerCase().contains(query) ||
                (item.serialNumber ?? '').toLowerCase().contains(query) ||
                (item.brand ?? '').toLowerCase().contains(query) ||
                (item.model ?? '').toLowerCase().contains(query) ||
                (item.condition ?? '').toLowerCase().contains(query) ||
                item.currentLocation.toLowerCase().contains(query) ||
                item.category.toLowerCase().contains(query);
          }).toList();
          final filteredMovements = data.movements.where((record) {
            if (query.isEmpty) return true;
            return record.itemName.toLowerCase().contains(query) ||
                record.itemQrCode.toLowerCase().contains(query) ||
                record.actorName.toLowerCase().contains(query) ||
                record.fromLocation.toLowerCase().contains(query) ||
                record.toLocation.toLowerCase().contains(query) ||
                (record.description ?? '').toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                if (_selectedIndex == 0) ...<Widget>[
                  _MobileHeroCard(
                    currentUser: widget.currentUser,
                    readyCount: readyCount,
                    outCount: outCount,
                    overdueCount: overdueCount,
                    onPair: _openPairing,
                  ),
                  const SizedBox(height: 18),
                  _MobileSectionTitle(
                    title: tr('Status singkat'),
                    caption: tr('Jumlah barang berdasarkan status.'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MobileSummaryCard(
                          title: tr('Tersedia'),
                          value: '$readyCount',
                          icon: Icons.inventory_2_rounded,
                          accent: StatusColors.of(context).available,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MobileSummaryCard(
                          title: tr('Dipinjam'),
                          value: '$outCount',
                          icon: Icons.call_made_rounded,
                          accent: StatusColors.of(context).borrowed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MobileSummaryCard(
                          title: tr('Terlambat'),
                          value: '$overdueCount',
                          icon: Icons.warning_amber_rounded,
                          accent: StatusColors.of(context).overdue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _MobileSectionTitle(
                    title: tr('Pergerakan terbaru'),
                    caption: tr('Aktivitas terbaru di seluruh alur peralatan.'),
                  ),
                  const SizedBox(height: 10),
                  ...data.movements.take(5).map(
                        (record) => _MobileMovementCard(record: record),
                      ),
                ],
                if (_selectedIndex != 0) ...<Widget>[
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: _selectedIndex == 1
                          ? tr('Cari barang, QR, nomor seri, merek, model, kategori, atau lokasi')
                          : tr('Cari barang, pelaku, kode QR, lokasi, atau keterangan'),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (_selectedIndex == 1) ...<Widget>[
                  _MobileSectionTitle(
                    title: tr('Barang'),
                    caption: tr('{count} barang ditampilkan', {'count': filteredItems.length}),
                  ),
                  const SizedBox(height: 10),
                  if (filteredItems.isEmpty)
                    _MobileEmptyState(
                      text: tr('Belum ada barang yang cocok dengan pencarian. Coba nama barang, kode QR, nomor seri, merek, model, kategori, atau lokasi.'),
                    )
                  else
                    ...filteredItems.map((item) => _MobileItemCard(item: item)),
                ],
                if (_selectedIndex == 2) ...<Widget>[
                  _MobileSectionTitle(
                    title: tr('Riwayat pergerakan'),
                    caption: tr('{count} catatan pergerakan yang cocok', {'count': filteredMovements.length}),
                  ),
                  const SizedBox(height: 10),
                  if (filteredMovements.isEmpty)
                    _MobileEmptyState(
                      text: tr('Belum ada pergerakan yang cocok dengan pencarian. Coba nama barang, kode QR, pelaku, atau lokasi.'),
                    )
                  else
                    ...filteredMovements.map((record) => _MobileMovementCard(record: record)),
                ],
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.dashboard_rounded), label: tr('Ringkasan')),
          NavigationDestination(icon: const Icon(Icons.inventory_2_rounded), label: tr('Barang')),
          NavigationDestination(icon: const Icon(Icons.history_rounded), label: tr('Pergerakan')),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openPairing,
              icon: const Icon(Icons.phonelink_setup_rounded),
              label: Text(tr('Sambungkan')),
            )
          : null,
    );
  }

  String get _pageTitle {
    switch (_selectedIndex) {
      case 0:
        return tr('Ringkasan');
      case 1:
        return tr('Barang');
      case 2:
        return tr('Pergerakan');
    }
    return tr('Ringkasan');
  }
}

class _MobileData {
  const _MobileData({
    required this.items,
    required this.movements,
  });

  final List<Item> items;
  final List<MovementRecord> movements;
}

class _MobileHeroCard extends StatelessWidget {
  const _MobileHeroCard({
    required this.currentUser,
    required this.readyCount,
    required this.outCount,
    required this.overdueCount,
    required this.onPair,
  });

  final AppUser currentUser;
  final int readyCount;
  final int outCount;
  final int overdueCount;
  final Future<void> Function() onPair;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF6D52F5), Color(0xFF5B39EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x305B39EA),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            tr('{ready} tersedia · {out} dipinjam · {overdue} terlambat', {'ready': readyCount, 'out': outCount, 'overdue': overdueCount}),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('Diperbarui otomatis'),
            style: const TextStyle(
              color: Color(0xFFF0ECFF),
              fontWeight: FontWeight.w600,
            ),
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
              tr('Masuk sebagai {name} ({badge})', {'name': currentUser.name, 'badge': currentUser.badgeId}),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPair,
            icon: const Icon(Icons.phonelink_setup_rounded),
            label: Text(tr('Sambungkan ke PC ruang peralatan')),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF5B39EA),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileSectionTitle extends StatelessWidget {
  const _MobileSectionTitle({
    required this.title,
    required this.caption,
  });

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2533),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: TextStyle(
            color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6A738A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MobileSummaryCard extends StatelessWidget {
  const _MobileSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF252B42) : const Color(0xFFECEFF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.14),
            foregroundColor: accent,
            child: Icon(icon),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1F2533),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6A738A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileItemCard extends StatelessWidget {
  const _MobileItemCard({
    required this.item,
  });

  final Item item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusLabel = itemStatusLabel(item);
    final statusAccent = StatusColors.of(context).color(itemStatusTone(item));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF252B42) : const Color(0xFFECEFF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1F2533),
                  ),
                ),
              ),
              _MobileStatusPill(
                label: statusLabel,
                accent: statusAccent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${item.qrCode} | ${item.serialNumber ?? tr('Tanpa nomor seri')}',
            style: TextStyle(
              color: isDark ? const Color(0xFFCFD4E6) : const Color(0xFF4A546B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.category} | ${item.currentLocation}',
            style: TextStyle(
              color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6A738A),
            ),
          ),
          if ((item.brand ?? '').isNotEmpty || (item.model ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              <String>[
                if ((item.brand ?? '').isNotEmpty) item.brand!,
                if ((item.model ?? '').isNotEmpty) item.model!,
              ].join(' / '),
              style: TextStyle(
                color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6A738A),
              ),
            ),
          ],
          if (item.expectedReturnAt != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              tr('Batas pengembalian: {date}', {'date': DateFormat('dd MMM yyyy', dateLocale).format(item.expectedReturnAt!)}),
              style: TextStyle(
                color: statusAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileMovementCard extends StatelessWidget {
  const _MobileMovementCard({
    required this.record,
  });

  final MovementRecord record;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // A borrow leaves the item "borrowed" (amber); a return makes it "available" (green).
    final statusColors = StatusColors.of(context);
    final accent = record.action == MovementAction.borrow ? statusColors.borrowed : statusColors.available;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF252B42) : const Color(0xFFECEFF6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  record.itemName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1F2533),
                  ),
                ),
              ),
              _MobileStatusPill(
                label: record.action == MovementAction.borrow ? tr('Pinjam') : tr('Kembali'),
                accent: accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${record.actorName} | ${record.fromLocation} -> ${record.toLocation}',
            style: TextStyle(
              color: isDark ? const Color(0xFFCFD4E6) : const Color(0xFF4A546B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'QR ${record.itemQrCode} | ${DateFormat('dd MMM yyyy, HH:mm', dateLocale).format(record.createdAt)}',
            style: TextStyle(
              color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6A738A),
            ),
          ),
          if ((record.description ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              record.description!,
              style: TextStyle(
                color: isDark ? const Color(0xFFB7C0D8) : const Color(0xFF59627A),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MobileEmptyState extends StatelessWidget {
  const _MobileEmptyState({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF252B42) : const Color(0xFFECEFF6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6A738A),
          height: 1.5,
        ),
      ),
    );
  }
}

class _MobileStatusPill extends StatelessWidget {
  const _MobileStatusPill({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: StatusColors.of(context).backgroundAlpha),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
