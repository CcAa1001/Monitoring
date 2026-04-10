import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/inventory_repository.dart';
import '../../models/item.dart';
import '../../models/movement_record.dart';
import '../workflow/action_flow_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
  });

  final InventoryRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeData> _load() async {
    final items = await widget.repository.getItems();
    final movements = await widget.repository.getRecentMovements();
    return _HomeData(items: items, movements: movements);
  }

  Future<void> _refresh() async {
    final data = await _load();
    if (!mounted) return;
    setState(() {
      _future = Future<_HomeData>.value(data);
    });
  }

  Future<void> _openFlow(WorkflowMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActionFlowScreen(
          repository: widget.repository,
          mode: mode,
        ),
      ),
    );

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final availableCount = data.items.where((item) => item.status == ItemStatus.available).length;
            final borrowedCount = data.items.where((item) => item.status == ItemStatus.borrowed).length;

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: <Widget>[
                  _HeaderCard(
                    onBorrowTap: () => _openFlow(WorkflowMode.borrow),
                    onReturnTap: () => _openFlow(WorkflowMode.returnItem),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MetricCard(
                          title: 'Ready to use',
                          value: '$availableCount',
                          color: const Color(0xFF0C6E6E),
                          icon: Icons.inventory_2_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          title: 'Currently out',
                          value: '$borrowedCount',
                          color: const Color(0xFFE58F2A),
                          icon: Icons.call_made_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Recent movements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF183A37),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...data.movements.map(_MovementTile.new),
                  const SizedBox(height: 18),
                  const Text(
                    'Room snapshot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF183A37),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...data.items.map(_ItemSnapshotTile.new),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.items,
    required this.movements,
  });

  final List<Item> items;
  final List<MovementRecord> movements;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.onBorrowTap,
    required this.onReturnTap,
  });

  final VoidCallback onBorrowTap;
  final VoidCallback onReturnTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF183A37),
            Color(0xFF0C6E6E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Scan. Confirm. Move.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'The right process should feel faster than skipping it. Users scan first, tap the correct destination, and finish in seconds.',
            style: TextStyle(
              color: Color(0xFFE3F2EF),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onBorrowTap,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Borrow item'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE58F2A),
                    foregroundColor: const Color(0xFF183A37),
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReturnTap,
                  icon: const Icon(Icons.assignment_return_rounded),
                  label: const Text('Return item'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF183A37),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF4C6A67),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile(this.record);

  final MovementRecord record;

  @override
  Widget build(BuildContext context) {
    final isBorrow = record.action == MovementAction.borrow;
    final formatter = DateFormat('dd MMM, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: (isBorrow ? const Color(0xFFE58F2A) : const Color(0xFF0C6E6E)).withOpacity(0.15),
            foregroundColor: isBorrow ? const Color(0xFFE58F2A) : const Color(0xFF0C6E6E),
            child: Icon(isBorrow ? Icons.call_made_rounded : Icons.call_received_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  record.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF183A37),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.actorName} • ${record.itemQrCode}',
                  style: const TextStyle(
                    color: Color(0xFF5D7470),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${record.fromLocation}  ->  ${record.toLocation}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF183A37),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatter.format(record.createdAt),
            style: const TextStyle(
              color: Color(0xFF5D7470),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSnapshotTile extends StatelessWidget {
  const _ItemSnapshotTile(this.item);

  final Item item;

  @override
  Widget build(BuildContext context) {
    final isAvailable = item.status == ItemStatus.available;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF183A37),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category} • ${item.qrCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5D7470),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.currentLocation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF183A37),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isAvailable ? const Color(0xFF0C6E6E) : const Color(0xFFE58F2A)).withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isAvailable ? 'Available' : 'Borrowed',
              style: TextStyle(
                color: isAvailable ? const Color(0xFF0C6E6E) : const Color(0xFFE58F2A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
