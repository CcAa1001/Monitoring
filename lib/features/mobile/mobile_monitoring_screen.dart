import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/inventory_repository.dart';
import '../../models/app_user.dart';
import '../../models/item.dart';
import '../../models/movement_record.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      '${widget.currentUser.badgeId} | ${widget.currentUser.role.name}',
                      style: const TextStyle(color: Color(0xFFF0ECFF), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_rounded),
                title: const Text('Overview'),
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
                title: const Text('Items'),
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
                title: const Text('Movement'),
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
                title: const Text('Pair scanner'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _openPairing();
                },
              ),
              ListTile(
                leading: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                title: const Text('Toggle theme'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onToggleTheme();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Refresh data'),
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
                    label: const Text('Log out'),
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
                  const _MobileSectionTitle(
                    title: 'Quick status',
                    caption: 'A cleaner mobile desk for monitoring and pairing.',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MobileSummaryCard(
                          title: 'Ready',
                          value: '$readyCount',
                          icon: Icons.inventory_2_rounded,
                          accent: const Color(0xFF16C098),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MobileSummaryCard(
                          title: 'Borrowed',
                          value: '$outCount',
                          icon: Icons.call_made_rounded,
                          accent: const Color(0xFFEA5455),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MobileSummaryCard(
                          title: 'Overdue',
                          value: '$overdueCount',
                          icon: Icons.warning_amber_rounded,
                          accent: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _MobileSectionTitle(
                    title: 'Recent movement',
                    caption: 'Latest activity across the equipment flow.',
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
                          ? 'Search item, QR, serial, brand, model, category, or location'
                          : 'Search item, actor, QR code, location, or description',
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
                    title: 'Items',
                    caption: '${filteredItems.length} item${filteredItems.length == 1 ? '' : 's'} in view',
                  ),
                  const SizedBox(height: 10),
                  if (filteredItems.isEmpty)
                    const _MobileEmptyState(
                      text: 'No items match that search yet. Try an item name, QR code, serial, brand, model, category, or location.',
                    )
                  else
                    ...filteredItems.map((item) => _MobileItemCard(item: item)),
                ],
                if (_selectedIndex == 2) ...<Widget>[
                  _MobileSectionTitle(
                    title: 'Movement history',
                    caption: '${filteredMovements.length} matching movement record${filteredMovements.length == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: 10),
                  if (filteredMovements.isEmpty)
                    const _MobileEmptyState(
                      text: 'No movement matches that search yet. Try an item name, QR code, actor, or location.',
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
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.inventory_2_rounded), label: 'Items'),
          NavigationDestination(icon: Icon(Icons.history_rounded), label: 'Movement'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openPairing,
              icon: const Icon(Icons.phonelink_setup_rounded),
              label: const Text('Pair'),
            )
          : null,
    );
  }

  String get _pageTitle {
    switch (_selectedIndex) {
      case 0:
        return 'Overview';
      case 1:
        return 'Items';
      case 2:
        return 'Movement';
    }
    return 'Overview';
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
          const Text(
            'Mobile monitoring desk',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monitor item status, review movement, and pair this phone as a scanner when the desk needs remote scans.',
            style: TextStyle(
              color: Color(0xFFF0ECFF),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(child: _MobileStatChip(label: 'Ready', value: '$readyCount')),
              const SizedBox(width: 10),
              Expanded(child: _MobileStatChip(label: 'Borrowed', value: '$outCount')),
              const SizedBox(width: 10),
              Expanded(child: _MobileStatChip(label: 'Overdue', value: '$overdueCount')),
            ],
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
              'Signed in as ${currentUser.name} (${currentUser.badgeId})',
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
            label: const Text('Pair with equipment-room PC'),
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
    final isReady = item.status == ItemStatus.available;
    final statusLabel = item.isOverdue
        ? 'Overdue'
        : item.isDueSoon
            ? 'Due soon'
            : isReady
                ? 'Ready'
                : 'Borrowed';
    final statusAccent = item.isOverdue
        ? const Color(0xFFEA5455)
        : item.isDueSoon
            ? const Color(0xFFF59E0B)
            : isReady
                ? const Color(0xFF16C098)
                : const Color(0xFFEA5455);
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
            '${item.qrCode} | ${item.serialNumber ?? 'No serial'}',
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
              'Expected return: ${DateFormat('dd MMM yyyy').format(item.expectedReturnAt!)}',
              style: TextStyle(
                color: item.isOverdue ? const Color(0xFFEA5455) : statusAccent,
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
    final accent = record.action == MovementAction.borrow ? const Color(0xFFE58F2A) : const Color(0xFF16C098);
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
                label: record.action == MovementAction.borrow ? 'Borrow' : 'Return',
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
            'QR ${record.itemQrCode} | ${DateFormat('dd MMM yyyy, HH:mm').format(record.createdAt)}',
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
        color: accent.withValues(alpha: 0.14),
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

class _MobileStatChip extends StatelessWidget {
  const _MobileStatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF0ECFF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
