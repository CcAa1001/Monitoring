part of 'desktop_shell_screen_v2.dart';

class DesktopDashboardOverviewPage extends StatelessWidget {
  const DesktopDashboardOverviewPage({
    super.key,
    required this.items,
    required this.users,
    required this.locations,
    required this.movements,
    required this.pairingSession,
    required this.onStartPairing,
    required this.onDisconnectPairing,
    required this.onBorrow,
    required this.onReturn,
    required this.userRole,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onViewItemHistory,
  });

  final List<Item> items;
  final List<AppUser> users;
  final List<AllowedLocation> locations;
  final List<MovementRecord> movements;
  final PairingSession? pairingSession;
  final VoidCallback onStartPairing;
  final Future<void> Function() onDisconnectPairing;
  final VoidCallback? onBorrow;
  final VoidCallback? onReturn;
  final UserRole userRole;
  final Future<void> Function({Item? item})? onEditItem;
  final Future<void> Function(Item item)? onDeleteItem;
  final Future<void> Function(Item item) onViewItemHistory;

  @override
  Widget build(BuildContext context) {
    final ready = items.where((item) => item.status == ItemStatus.available).length;
    final borrowed = items.where((item) => item.status == ItemStatus.borrowed).length;

    return ListView(
      children: <Widget>[
        const DesktopSectionHeader(
          title: 'Dashboard',
          subtitle: 'Overview and faster desk controls',
        ),
        const SizedBox(height: 18),
        _DashboardControlPanel(
          pairingSession: pairingSession,
          onStartPairing: onStartPairing,
          onDisconnectPairing: onDisconnectPairing,
          onBorrow: onBorrow,
          onReturn: onReturn,
          userRole: userRole,
          readyCount: ready,
          scansToday: movements.where((movement) {
            final now = DateTime.now();
            return movement.createdAt.year == now.year &&
                movement.createdAt.month == now.month &&
                movement.createdAt.day == now.day;
          }).length,
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(child: DesktopMetricCard(title: 'Items ready', value: '$ready', icon: Icons.inventory_2_rounded)),
            const SizedBox(width: 12),
            Expanded(child: DesktopMetricCard(title: 'Currently out', value: '$borrowed', icon: Icons.call_made_rounded)),
            const SizedBox(width: 12),
            Expanded(child: DesktopMetricCard(title: 'Users', value: '${users.length}', icon: Icons.people_alt_rounded)),
            const SizedBox(width: 12),
            Expanded(child: DesktopMetricCard(title: 'Locations', value: '${locations.length}', icon: Icons.grid_view_rounded)),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: _DashboardMovementPanel(movements: movements),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 7,
              child: _DashboardEquipmentPanel(
                items: items,
                canManage: onEditItem != null && onDeleteItem != null,
                onEditItem: onEditItem,
                onDeleteItem: onDeleteItem,
                onViewItemHistory: onViewItemHistory,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardControlPanel extends StatelessWidget {
  const _DashboardControlPanel({
    required this.pairingSession,
    required this.onStartPairing,
    required this.onDisconnectPairing,
    required this.onBorrow,
    required this.onReturn,
    required this.userRole,
    required this.readyCount,
    required this.scansToday,
  });

  final PairingSession? pairingSession;
  final VoidCallback onStartPairing;
  final Future<void> Function() onDisconnectPairing;
  final VoidCallback? onBorrow;
  final VoidCallback? onReturn;
  final UserRole userRole;
  final int readyCount;
  final int scansToday;

  @override
  Widget build(BuildContext context) {
    return DesktopPanel(
      title: 'Equipment-room control desk',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: DesktopMetricCard(title: 'Ready now', value: '$readyCount', icon: Icons.inventory_2_rounded)),
              const SizedBox(width: 12),
              Expanded(child: DesktopMetricCard(title: 'Scans today', value: '$scansToday', icon: Icons.qr_code_scanner_rounded)),
              const SizedBox(width: 12),
              Expanded(
                child: DesktopMetricCard(
                  title: 'Pairing',
                  value: pairingSession == null ? 'OFF' : 'ON',
                  icon: Icons.phonelink_ring_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStartPairing,
                  icon: const Icon(Icons.phonelink_setup_rounded),
                  label: Text(pairingSession == null ? 'Pair phone' : 'Open pair QR'),
                ),
              ),
              if (pairingSession != null) ...<Widget>[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onDisconnectPairing(),
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Unpair phone'),
                  ),
                ),
              ],
            ],
          ),
          if (pairingSession != null) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              'Active pair code: ${pairingSession!.code}${(pairingSession!.connectedDeviceName ?? '').isEmpty ? '' : ' | ${pairingSession!.connectedDeviceName}'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            userRole == UserRole.viewer
                ? 'Viewer mode is active. Monitoring is enabled, but transaction buttons are disabled.'
                : 'Transactional mode is active on this terminal.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (userRole != UserRole.viewer) ...<Widget>[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onBorrow,
                  icon: const Icon(Icons.call_made_rounded),
                  label: const Text('Borrow items'),
                ),
                OutlinedButton.icon(
                  onPressed: onReturn,
                  icon: const Icon(Icons.assignment_return_rounded),
                  label: const Text('Return items'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardMovementPanel extends StatefulWidget {
  const _DashboardMovementPanel({
    required this.movements,
  });

  final List<MovementRecord> movements;

  @override
  State<_DashboardMovementPanel> createState() => _DashboardMovementPanelState();
}

class _DashboardMovementPanelState extends State<_DashboardMovementPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MovementRecord> get _filteredMovements {
    final query = _searchController.text.trim().toLowerCase();
    return widget.movements.where((record) {
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Borrow' && record.action == MovementAction.borrow) ||
          (_filter == 'Return' && record.action == MovementAction.returnItem);
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return record.itemName.toLowerCase().contains(query) ||
          record.itemQrCode.toLowerCase().contains(query) ||
          record.actorName.toLowerCase().contains(query) ||
          record.fromLocation.toLowerCase().contains(query) ||
          record.toLocation.toLowerCase().contains(query) ||
          (record.description ?? '').toLowerCase().contains(query);
    }).take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopPanel(
      title: 'Recent movements',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search item, QR, actor, location, or note',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Borrow', child: Text('Borrow')),
                    DropdownMenuItem(value: 'Return', child: Text('Return')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _filter = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Filter'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_filteredMovements.isEmpty)
            const Text('No movements match the current search and filter.')
          else
            ..._filteredMovements.map((record) => _DashboardMovementTile(record: record)),
        ],
      ),
    );
  }
}

class _DashboardEquipmentPanel extends StatefulWidget {
  const _DashboardEquipmentPanel({
    required this.items,
    required this.canManage,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onViewItemHistory,
  });

  final List<Item> items;
  final bool canManage;
  final Future<void> Function({Item? item})? onEditItem;
  final Future<void> Function(Item item)? onDeleteItem;
  final Future<void> Function(Item item) onViewItemHistory;

  @override
  State<_DashboardEquipmentPanel> createState() => _DashboardEquipmentPanelState();
}

class _DashboardEquipmentPanelState extends State<_DashboardEquipmentPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Item> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return widget.items.where((item) {
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Ready' && item.status == ItemStatus.available) ||
          (_filter == 'Borrowed' && item.status == ItemStatus.borrowed);
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.qrCode.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.currentLocation.toLowerCase().contains(query);
    }).take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopPanel(
      title: 'Equipment snapshot',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search item, QR, category, or location',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Ready', child: Text('Ready')),
                    DropdownMenuItem(value: 'Borrowed', child: Text('Borrowed')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _filter = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_filteredItems.isEmpty)
            const Text('No equipment matches the current search and filter.')
          else
            ..._filteredItems.map((item) {
              return DesktopSimpleTile(
                title: item.name,
                subtitle: '${item.qrCode} • ${item.category} • ${item.currentLocation}',
                status: item.status == ItemStatus.available ? 'Ready' : 'Borrowed',
                onHistory: () => widget.onViewItemHistory(item),
                onEdit: widget.canManage ? () => widget.onEditItem?.call(item: item) : null,
                onDelete: widget.canManage ? () => widget.onDeleteItem?.call(item) : null,
              );
            }),
        ],
      ),
    );
  }
}

class _DashboardMovementTile extends StatelessWidget {
  const _DashboardMovementTile({
    required this.record,
  });

  final MovementRecord record;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2238) : const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            record.itemName,
            style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1F2533)),
          ),
          const SizedBox(height: 4),
          Text('${record.actorName} • ${record.fromLocation} -> ${record.toLocation}'),
          const SizedBox(height: 4),
          Text('QR ${record.itemQrCode} • ${formatter.format(record.createdAt)}'),
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
