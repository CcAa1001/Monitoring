import 'package:flutter/material.dart';

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
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factory monitoring'),
        actions: <Widget>[
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
          ),
        ],
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
          final query = _searchController.text.trim().toLowerCase();
          final filteredItems = data.items.where((item) {
            if (query.isEmpty) return true;
            return item.name.toLowerCase().contains(query) ||
                item.qrCode.toLowerCase().contains(query) ||
                item.currentLocation.toLowerCase().contains(query);
          }).toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
              Container(
                padding: const EdgeInsets.all(18),
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
                      'Viewer mode on mobile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Track item status, review recent movement, and pair a phone scanner with the equipment-room desktop when needed.',
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
                        Expanded(child: _MobileStatChip(label: 'Out', value: '$outCount')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.16)),
                      ),
                      child: Text(
                        'Signed in as ${widget.currentUser.name} (${widget.currentUser.badgeId})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MobilePairScreen(
                              repository: widget.repository,
                              currentUser: widget.currentUser,
                            ),
                          ),
                        );
                        await _refresh();
                      },
                      icon: const Icon(Icons.phonelink_setup_rounded),
                      label: const Text('Pair with equipment-room PC'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5B39EA),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Search item, QR code, or location',
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
              const Text(
                'Current items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                query.isEmpty
                    ? '${data.items.length} items in view'
                    : '${filteredItems.length} matching items',
                style: const TextStyle(
                  color: Color(0xFF6A738A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (filteredItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECEFf6)),
                  ),
                  child: const Text(
                    'No items match that search yet. Try an item name, QR code, or location.',
                    style: TextStyle(
                      color: Color(0xFF6A738A),
                      height: 1.5,
                    ),
                  ),
                ),
              ...filteredItems.map((item) => ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Color(0xFFECEFf6)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    title: Text(item.name),
                    subtitle: Text('${item.qrCode} • ${item.currentLocation}'),
                    trailing: Text(
                      item.status == ItemStatus.available ? 'Ready' : 'Out',
                      style: TextStyle(
                        color: item.status == ItemStatus.available
                            ? const Color(0xFF16C098)
                            : const Color(0xFFEA5455),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )),
              const SizedBox(height: 18),
              const Text(
                'Recent movement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...data.movements.take(5).map(
                    (record) => ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFECEFf6)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      title: Text(record.itemName),
                      subtitle: Text('${record.actorName} • ${record.fromLocation} -> ${record.toLocation}'),
                    ),
                  ),
            ],
            ),
          );
        },
      ),
    );
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
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
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
