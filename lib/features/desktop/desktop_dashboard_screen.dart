import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/inventory_repository.dart';
import '../../models/item.dart';
import '../../models/movement_record.dart';
import '../../models/pairing_session.dart';
import '../workflow/action_flow_screen.dart';

class DesktopDashboardScreen extends StatefulWidget {
  const DesktopDashboardScreen({
    super.key,
    required this.repository,
  });

  final InventoryRepository repository;

  @override
  State<DesktopDashboardScreen> createState() => _DesktopDashboardScreenState();
}

class _DesktopDashboardScreenState extends State<DesktopDashboardScreen> {
  late Future<_DesktopData> _future;
  PairingSession? _pairingSession;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DesktopData> _load() async {
    final items = await widget.repository.getItems();
    final movements = await widget.repository.getRecentMovements();
    return _DesktopData(items: items, movements: movements);
  }

  Future<void> _refresh() async {
    final data = await _load();
    if (!mounted) return;
    setState(() {
      _future = Future<_DesktopData>.value(data);
    });
  }

  Future<void> _openFlow(WorkflowMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActionFlowScreen(
          repository: widget.repository,
          mode: mode,
          pairingSession: _pairingSession,
          desktopOnly: true,
          currentUser: null,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _startPairing() async {
    final session = await widget.repository.createPairingSession();
    if (!mounted) return;
    setState(() {
      _pairingSession = session;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_DesktopData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;
            final availableCount = data.items.where((item) => item.status == ItemStatus.available).length;
            final borrowedCount = data.items.where((item) => item.status == ItemStatus.borrowed).length;

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: _DesktopHero(
                        onBorrowTap: () => _openFlow(WorkflowMode.borrow),
                        onReturnTap: () => _openFlow(WorkflowMode.returnItem),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: _PairingPanel(
                        session: _pairingSession,
                        onStartPairing: _startPairing,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _DesktopMetricCard(
                        title: 'Ready to use',
                        value: '$availableCount',
                        accent: const Color(0xFF0C6E6E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DesktopMetricCard(
                        title: 'Currently out',
                        value: '$borrowedCount',
                        accent: const Color(0xFFE58F2A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _DesktopSection(
                        title: 'Recent movements',
                        child: Column(
                          children: data.movements.map(_DesktopMovementTile.new).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DesktopSection(
                        title: 'Equipment room status',
                        child: Column(
                          children: data.items.map(_DesktopItemTile.new).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DesktopData {
  const _DesktopData({
    required this.items,
    required this.movements,
  });

  final List<Item> items;
  final List<MovementRecord> movements;
}

class _DesktopHero extends StatelessWidget {
  const _DesktopHero({
    required this.onBorrowTap,
    required this.onReturnTap,
  });

  final VoidCallback onBorrowTap;
  final VoidCallback onReturnTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF183A37), Color(0xFF0C6E6E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Equipment-room control desk',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Borrow and return are only confirmed here, so every movement is tied to the room where the equipment physically exists.',
            style: TextStyle(
              color: Color(0xFFE3F2EF),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: onBorrowTap,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Borrow on this PC'),
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
                  label: const Text('Return on this PC'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
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

class _PairingPanel extends StatelessWidget {
  const _PairingPanel({
    required this.session,
    required this.onStartPairing,
  });

  final PairingSession? session;
  final VoidCallback onStartPairing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Phone pairing',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'A phone may scan for this PC session, but the final borrow or return still requires confirmation here.',
            style: TextStyle(height: 1.5, color: Color(0xFF5D7470)),
          ),
          const SizedBox(height: 18),
          if (session == null) ...<Widget>[
            FilledButton.icon(
              onPressed: onStartPairing,
              icon: const Icon(Icons.phonelink_setup_rounded),
              label: const Text('Create pairing session'),
            ),
          ] else ...<Widget>[
            Text(
              'Session code: ${session!.code}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              session!.status == PairingSessionStatus.connected
                  ? 'Connected phone: ${session!.connectedDeviceName ?? 'Unknown device'}'
                  : 'Waiting for a phone to connect',
            ),
            const SizedBox(height: 8),
            Text(
              'Last scan from phone: ${session!.lastScannedQr ?? '-'}',
              style: const TextStyle(color: Color(0xFF5D7470)),
            ),
          ],
        ],
      ),
    );
  }
}

class _DesktopMetricCard extends StatelessWidget {
  const _DesktopMetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

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
          Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 4),
          Text(title),
        ],
      ),
    );
  }
}

class _DesktopSection extends StatelessWidget {
  const _DesktopSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DesktopMovementTile extends StatelessWidget {
  const _DesktopMovementTile(this.record);

  final MovementRecord record;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(record.itemName, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${record.actorName} • ${record.fromLocation} -> ${record.toLocation}'),
              ],
            ),
          ),
          Text(formatter.format(record.createdAt)),
        ],
      ),
    );
  }
}

class _DesktopItemTile extends StatelessWidget {
  const _DesktopItemTile(this.item);

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${item.qrCode} • ${item.currentLocation}'),
              ],
            ),
          ),
          Text(
            item.status == ItemStatus.available ? 'Ready' : 'Out',
            style: TextStyle(
              color: item.status == ItemStatus.available
                  ? const Color(0xFF0C6E6E)
                  : const Color(0xFFE58F2A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
