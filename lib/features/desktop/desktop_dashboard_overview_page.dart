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
    final scansToday = movements.where((movement) {
      final now = DateTime.now();
      return movement.createdAt.year == now.year &&
          movement.createdAt.month == now.month &&
          movement.createdAt.day == now.day;
    }).length;

    return ListView(
      children: <Widget>[
        _DashboardHeroPanel(
          pairingSession: pairingSession,
          userRole: userRole,
          onStartPairing: onStartPairing,
          onDisconnectPairing: onDisconnectPairing,
          onBorrow: onBorrow,
          onReturn: onReturn,
          readyCount: ready,
          borrowedCount: borrowed,
          scansToday: scansToday,
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
        _DashboardMovementPanel(movements: movements),
        const SizedBox(height: 18),
        _DashboardEquipmentPanel(
          items: items,
          canManage: onEditItem != null && onDeleteItem != null,
          onEditItem: onEditItem,
          onDeleteItem: onDeleteItem,
          onViewItemHistory: onViewItemHistory,
        ),
      ],
    );
  }
}

class _DashboardHeroPanel extends StatelessWidget {
  const _DashboardHeroPanel({
    required this.pairingSession,
    required this.userRole,
    required this.onStartPairing,
    required this.onDisconnectPairing,
    required this.onBorrow,
    required this.onReturn,
    required this.readyCount,
    required this.borrowedCount,
    required this.scansToday,
  });

  final PairingSession? pairingSession;
  final UserRole userRole;
  final VoidCallback onStartPairing;
  final Future<void> Function() onDisconnectPairing;
  final VoidCallback? onBorrow;
  final VoidCallback? onReturn;
  final int readyCount;
  final int borrowedCount;
  final int scansToday;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const <Color>[Color(0xFF1E2440), Color(0xFF151A2B)]
              : const <Color>[Color(0xFFF7F4FF), Color(0xFFFDFDFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF29314C) : const Color(0xFFE9EAF4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B39EA).withValues(alpha: isDark ? 0.24 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    pairingSession == null ? 'Desk mode active' : 'Phone pairing active',
                    style: TextStyle(
                      color: const Color(0xFF5B39EA),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Run the equipment room from one calmer dashboard.',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1F2533),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userRole == UserRole.viewer
                      ? 'This account is in monitoring mode. You can review activity and pairing health, but borrow and return actions stay locked.'
                      : 'Start a desk scan, hand scanning to a paired phone, or jump directly into borrow and return workflows without leaving the hub.',
                  style: TextStyle(
                    height: 1.6,
                    color: isDark ? const Color(0xFFB4BDD4) : const Color(0xFF687189),
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: onStartPairing,
                      icon: const Icon(Icons.phonelink_setup_rounded),
                      label: Text(pairingSession == null ? 'Pair a phone' : 'Open pair QR'),
                    ),
                    if (pairingSession != null)
                      OutlinedButton.icon(
                        onPressed: () => onDisconnectPairing(),
                        icon: const Icon(Icons.link_off_rounded),
                        label: const Text('Disconnect phone'),
                      ),
                    if (userRole != UserRole.viewer)
                      OutlinedButton.icon(
                        onPressed: onBorrow,
                        icon: const Icon(Icons.call_made_rounded),
                        label: const Text('Borrow flow'),
                      ),
                    if (userRole != UserRole.viewer)
                      OutlinedButton.icon(
                        onPressed: onReturn,
                        icon: const Icon(Icons.assignment_return_rounded),
                        label: const Text('Return flow'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111726) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF28304A) : const Color(0xFFECEFF6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Live desk snapshot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1F2533),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(child: _DashboardInfoStat(label: 'Ready', value: '$readyCount')),
                      const SizedBox(width: 10),
                      Expanded(child: _DashboardInfoStat(label: 'Borrowed', value: '$borrowedCount')),
                      const SizedBox(width: 10),
                      Expanded(child: _DashboardInfoStat(label: 'Scans today', value: '$scansToday')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DashboardInfoRow(
                    icon: Icons.qr_code_2_rounded,
                    label: 'Pair code',
                    value: pairingSession?.code ?? 'Not created yet',
                  ),
                  const SizedBox(height: 12),
                  _DashboardInfoRow(
                    icon: Icons.smartphone_rounded,
                    label: 'Connected device',
                    value: pairingSession?.connectedDeviceName ?? 'No phone paired',
                  ),
                  const SizedBox(height: 12),
                  _DashboardInfoRow(
                    icon: Icons.flash_on_rounded,
                    label: 'Last scan',
                    value: pairingSession?.lastScannedQr ?? 'Waiting for scan',
                  ),
                ],
              ),
            ),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DashboardPanelHeader(
            title: 'Recent movements',
            caption: 'Track the latest equipment movement with search and action filtering.',
          ),
          const SizedBox(height: 18),
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
                width: 170,
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'All', child: Text('All activity')),
                    DropdownMenuItem(value: 'Borrow', child: Text('Borrow only')),
                    DropdownMenuItem(value: 'Return', child: Text('Return only')),
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
          const SizedBox(height: 18),
          if (_filteredMovements.isEmpty)
            const Text('No movements match the current search and filter.')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 980;
                if (!twoColumns) {
                  return Column(
                    children: _filteredMovements
                        .map((record) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DashboardMovementTile(record: record),
                            ))
                        .toList(),
                  );
                }
                final left = <MovementRecord>[];
                final right = <MovementRecord>[];
                for (var i = 0; i < _filteredMovements.length; i++) {
                  if (i.isEven) {
                    left.add(_filteredMovements[i]);
                  } else {
                    right.add(_filteredMovements[i]);
                  }
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: left
                            .map((record) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _DashboardMovementTile(record: record),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: right
                            .map((record) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _DashboardMovementTile(record: record),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DashboardPanelHeader(
            title: 'Equipment snapshot',
            caption: 'Review the current state of the room and jump straight into item actions.',
          ),
          const SizedBox(height: 18),
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
                width: 170,
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'All', child: Text('All status')),
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
          const SizedBox(height: 18),
          if (_filteredItems.isEmpty)
            const Text('No equipment matches the current search and filter.')
          else
            ..._filteredItems.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DesktopSimpleTile(
                  title: item.name,
                  subtitle: '${item.qrCode} | ${item.category} | ${item.currentLocation}',
                  status: item.status == ItemStatus.available ? 'Ready' : 'Borrowed',
                  onHistory: () => widget.onViewItemHistory(item),
                  onEdit: widget.canManage ? () => widget.onEditItem?.call(item: item) : null,
                  onDelete: widget.canManage ? () => widget.onDeleteItem?.call(item) : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DashboardPanelHeader extends StatelessWidget {
  const _DashboardPanelHeader({
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
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1F2533),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: TextStyle(
            color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF6C748B),
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _DashboardInfoStat extends StatelessWidget {
  const _DashboardInfoStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF181E31) : const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF7E8698),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1F2533),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardInfoRow extends StatelessWidget {
  const _DashboardInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF5B39EA).withValues(alpha: isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF5B39EA)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF7E8698),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1F2533),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
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
    final accent = record.action == MovementAction.borrow ? const Color(0xFF5B39EA) : const Color(0xFF14B8A6);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2034) : const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF2A314C) : const Color(0xFFECEFF6),
        ),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF1F2533),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.action == MovementAction.borrow ? 'Borrow' : 'Return',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _DashboardMetaChip(icon: Icons.person_rounded, text: record.actorName),
              _DashboardMetaChip(icon: Icons.qr_code_2_rounded, text: 'QR ${record.itemQrCode}'),
              _DashboardMetaChip(icon: Icons.schedule_rounded, text: formatter.format(record.createdAt)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _DashboardLocationPill(
                  label: 'From',
                  value: record.fromLocation,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.east_rounded, color: Color(0xFF7E8698)),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardLocationPill(
                  label: 'To',
                  value: record.toLocation,
                ),
              ),
            ],
          ),
          if ((record.description ?? '').isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111726) : const Color(0xFFF5F7FC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                record.description!,
                style: TextStyle(
                  color: isDark ? const Color(0xFFD0D6E7) : const Color(0xFF55607B),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardMetaChip extends StatelessWidget {
  const _DashboardMetaChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111726) : const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: const Color(0xFF7E8698)),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isDark ? const Color(0xFFD4D9E7) : const Color(0xFF55607B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLocationPill extends StatelessWidget {
  const _DashboardLocationPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111726) : const Color(0xFFF5F7FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF7E8698),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1F2533),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
