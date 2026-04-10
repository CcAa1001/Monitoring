import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/inventory_repository.dart';
import '../../models/allowed_location.dart';
import '../../models/app_user.dart';
import '../../models/item.dart';
import '../../models/movement_record.dart';
import '../../models/pairing_session.dart';
import '../workflow/action_flow_screen.dart';

const _pageBg = Color(0xFFF7F8FC);
const _sidebarBg = Color(0xFFFFFFFF);
const _cardBorder = Color(0xFFECEFf6);
const _softText = Color(0xFF7E8698);
const _titleText = Color(0xFF1F2533);
const _accent = Color(0xFF5B39EA);
const _accentSoft = Color(0xFFF0ECFF);
const _success = Color(0xFF16C098);
const _danger = Color(0xFFEA5455);

enum DesktopMenu {
  dashboard,
  transactions,
  history,
  items,
  locations,
  users,
  settings,
}

class DesktopShellScreen extends StatefulWidget {
  const DesktopShellScreen({
    super.key,
    required this.repository,
    required this.themeMode,
    required this.onToggleTheme,
  });

  final InventoryRepository repository;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  @override
  State<DesktopShellScreen> createState() => _DesktopShellScreenState();
}

class _DesktopShellScreenState extends State<DesktopShellScreen> {
  DesktopMenu _selectedMenu = DesktopMenu.dashboard;
  PairingSession? _pairingSession;
  late Future<_DesktopData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DesktopData> _load() async {
    final items = await widget.repository.getItems();
    final movements = await widget.repository.getRecentMovements();
    final locations = await widget.repository.getAllowedLocations();
    final users = await widget.repository.getUsers();
    return _DesktopData(
      items: items,
      movements: movements,
      locations: locations,
      users: users,
    );
  }

  Future<void> _refresh() async {
    final data = await _load();
    if (!mounted) return;
    setState(() {
      _future = Future<_DesktopData>.value(data);
    });
  }

  Future<void> _openTransaction(WorkflowMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ActionFlowScreen(
          repository: widget.repository,
          mode: mode,
          pairingSession: _pairingSession,
          desktopOnly: true,
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
            return Row(
              children: <Widget>[
                _Sidebar(
                  selectedMenu: _selectedMenu,
                  themeMode: widget.themeMode,
                  onToggleTheme: widget.onToggleTheme,
                  onSelect: (menu) {
                    setState(() {
                      _selectedMenu = menu;
                    });
                  },
                ),
                Expanded(
                  child: Container(
                    color: _pageBg,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey<DesktopMenu>(_selectedMenu),
                          child: _DesktopContent(
                            selectedMenu: _selectedMenu,
                            data: data,
                            pairingSession: _pairingSession,
                            onStartPairing: _startPairing,
                            onBorrowTap: () => _openTransaction(WorkflowMode.borrow),
                            onReturnTap: () => _openTransaction(WorkflowMode.returnItem),
                            onRefresh: _refresh,
                            repository: widget.repository,
                          ),
                        ),
                      ),
                    ),
                  ),
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
    required this.locations,
    required this.users,
  });

  final List<Item> items;
  final List<MovementRecord> movements;
  final List<AllowedLocation> locations;
  final List<AppUser> users;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedMenu,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onSelect,
  });

  final DesktopMenu selectedMenu;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final ValueChanged<DesktopMenu> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 260,
      color: isDark ? const Color(0xFF171B2D) : _sidebarBg,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Factory\nMonitoring',
            style: TextStyle(
              color: _titleText,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Official equipment-room terminal',
            style: TextStyle(color: _softText),
          ),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'MAIN MENU',
                  style: TextStyle(
                    color: const Color(0xFF9197B3).withOpacity(0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleTheme,
                icon: Icon(
                  themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: const Color(0xFF9197B3),
                ),
                tooltip: 'Toggle theme',
              ),
            ],
          ),
          ...DesktopMenu.values.map((menu) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SidebarButton(
                label: _menuLabel(menu),
                icon: _menuIcon(menu),
                selected: menu == selectedMenu,
                onTap: () => onSelect(menu),
              ),
            );
          }),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFD8CFFF), Color(0xFF5B39EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x305B39EA),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: const Text(
              'Borrow and return are confirmed only from this desktop view to keep the physical and digital process aligned.',
              style: TextStyle(color: Colors.white, height: 1.4, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _menuLabel(DesktopMenu menu) {
    switch (menu) {
      case DesktopMenu.dashboard:
        return 'Dashboard';
      case DesktopMenu.transactions:
        return 'Transactions';
      case DesktopMenu.history:
        return 'History';
      case DesktopMenu.items:
        return 'Items';
      case DesktopMenu.locations:
        return 'Locations';
      case DesktopMenu.users:
        return 'Users';
      case DesktopMenu.settings:
        return 'Settings';
    }
  }

  IconData _menuIcon(DesktopMenu menu) {
    switch (menu) {
      case DesktopMenu.dashboard:
        return Icons.dashboard_rounded;
      case DesktopMenu.transactions:
        return Icons.swap_horiz_rounded;
      case DesktopMenu.history:
        return Icons.history_rounded;
      case DesktopMenu.items:
        return Icons.inventory_2_rounded;
      case DesktopMenu.locations:
        return Icons.grid_view_rounded;
      case DesktopMenu.users:
        return Icons.people_alt_rounded;
      case DesktopMenu.settings:
        return Icons.settings_rounded;
    }
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: selected ? Colors.white : (isDark ? const Color(0xFFB3BCD4) : const Color(0xFF9197B3))),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : (isDark ? const Color(0xFFB3BCD4) : const Color(0xFF9197B3)),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopContent extends StatelessWidget {
  const _DesktopContent({
    required this.selectedMenu,
    required this.data,
    required this.pairingSession,
    required this.onStartPairing,
    required this.onBorrowTap,
    required this.onReturnTap,
    required this.onRefresh,
    required this.repository,
  });

  final DesktopMenu selectedMenu;
  final _DesktopData data;
  final PairingSession? pairingSession;
  final VoidCallback onStartPairing;
  final VoidCallback onBorrowTap;
  final VoidCallback onReturnTap;
  final Future<void> Function() onRefresh;
  final InventoryRepository repository;

  @override
  Widget build(BuildContext context) {
    late final Widget content;
    switch (selectedMenu) {
      case DesktopMenu.dashboard:
        content = _DashboardView(
          data: data,
          pairingSession: pairingSession,
          onStartPairing: onStartPairing,
          onBorrowTap: onBorrowTap,
          onReturnTap: onReturnTap,
        );
        break;
      case DesktopMenu.transactions:
        content = _TransactionsView(
          pairingSession: pairingSession,
          onBorrowTap: onBorrowTap,
          onReturnTap: onReturnTap,
        );
        break;
      case DesktopMenu.history:
        content = _HistoryView(movements: data.movements);
        break;
      case DesktopMenu.items:
        content = _ItemsView(
          items: data.items,
          repository: repository,
          onRefresh: onRefresh,
        );
        break;
      case DesktopMenu.locations:
        content = _LocationsView(
          locations: data.locations,
          repository: repository,
          onRefresh: onRefresh,
        );
        break;
      case DesktopMenu.users:
        content = _UsersView(
          users: data.users,
          repository: repository,
          onRefresh: onRefresh,
        );
        break;
      case DesktopMenu.settings:
        content = _SettingsView(pairingSession: pairingSession);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          _menuTitle(selectedMenu),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _softText,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(child: content),
      ],
    );
  }

  String _menuTitle(DesktopMenu menu) {
    switch (menu) {
      case DesktopMenu.dashboard:
        return 'Overview';
      case DesktopMenu.transactions:
        return 'Transactions';
      case DesktopMenu.history:
        return 'History';
      case DesktopMenu.items:
        return 'Items';
      case DesktopMenu.locations:
        return 'Locations';
      case DesktopMenu.users:
        return 'Users';
      case DesktopMenu.settings:
        return 'Settings';
    }
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({
    required this.data,
    required this.pairingSession,
    required this.onStartPairing,
    required this.onBorrowTap,
    required this.onReturnTap,
  });

  final _DesktopData data;
  final PairingSession? pairingSession;
  final VoidCallback onStartPairing;
  final VoidCallback onBorrowTap;
  final VoidCallback onReturnTap;

  @override
  Widget build(BuildContext context) {
    final availableCount = data.items.where((item) => item.status == ItemStatus.available).length;
    final borrowedCount = data.items.where((item) => item.status == ItemStatus.borrowed).length;

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: _HeroCard(
                onBorrowTap: onBorrowTap,
                onReturnTap: onReturnTap,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _PairingPanel(
                session: pairingSession,
                onStartPairing: onStartPairing,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(child: _MetricCard(title: 'Ready to use', value: '$availableCount', accent: const Color(0xFF0C6E6E))),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(title: 'Currently out', value: '$borrowedCount', accent: const Color(0xFFE58F2A))),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(title: 'Registered users', value: '${data.users.length}', accent: const Color(0xFF3E5C76))),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(title: 'Allowed locations', value: '${data.locations.length}', accent: const Color(0xFFB56576))),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _Panel(title: 'Recent movements', child: Column(children: data.movements.map(_MovementRow.new).toList()))),
            const SizedBox(width: 16),
            Expanded(child: _Panel(title: 'Equipment room snapshot', child: Column(children: data.items.take(8).map(_ItemRow.new).toList()))),
          ],
        ),
        ],
      ),
    );
  }
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView({
    required this.pairingSession,
    required this.onBorrowTap,
    required this.onReturnTap,
  });

  final PairingSession? pairingSession;
  final VoidCallback onBorrowTap;
  final VoidCallback onReturnTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
        const _PageHeader(
          title: 'Transactions',
          subtitle: 'All borrow and return confirmation happens here on the equipment-room PC.',
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionCard(
                title: 'Borrow item',
                description: 'Scan on this PC or use the paired phone scan, then confirm borrower and line.',
                actionLabel: 'Start borrow',
                accent: const Color(0xFFE58F2A),
                onTap: onBorrowTap,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ActionCard(
                title: 'Return item',
                description: 'Confirm rack placement on the PC so the next person can find the item correctly.',
                actionLabel: 'Start return',
                accent: const Color(0xFF0C6E6E),
                onTap: onReturnTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Pairing status',
          child: Text(
            pairingSession == null
                ? 'No phone is paired right now. Create a pairing session from the dashboard when you want a phone to scan for this PC.'
                : 'Active session: ${pairingSession!.code} • Device: ${pairingSession!.connectedDeviceName ?? 'waiting'} • Last scan: ${pairingSession!.lastScannedQr ?? '-'}',
            style: const TextStyle(height: 1.5),
          ),
        ),
        ],
      ),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView({
    required this.movements,
  });

  final List<MovementRecord> movements;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
        const _PageHeader(
          title: 'History',
          subtitle: 'Audit trail of item movements for monitoring, review, and thesis screenshots.',
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Movement log',
          child: Column(children: movements.map(_DetailedMovementRow.new).toList()),
        ),
        ],
      ),
    );
  }
}

class _ItemsView extends StatelessWidget {
  const _ItemsView({
    required this.items,
    required this.repository,
    required this.onRefresh,
  });

  final List<Item> items;
  final InventoryRepository repository;
  final Future<void> Function() onRefresh;

  Future<void> _openEditor(BuildContext context, {Item? item}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ItemEditorDialog(repository: repository, item: item),
    );
    await onRefresh();
  }

  Future<void> _deleteItem(BuildContext context, Item item) async {
    await repository.deleteItem(item.id);
    await onRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: _PageHeader(
                title: 'Items',
                subtitle: 'Register, edit, and remove equipment items and their QR identity.',
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Register item'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Item master',
          child: Column(
            children: items.map((item) {
              return _CrudRow(
                title: item.name,
                subtitle: '${item.qrCode} • ${item.category} • ${item.currentLocation}',
                trailing: item.status == ItemStatus.available ? 'Ready' : 'Borrowed',
                onEdit: () => _openEditor(context, item: item),
                onDelete: () => _deleteItem(context, item),
              );
            }).toList(),
          ),
        ),
        ],
      ),
    );
  }
}

class _LocationsView extends StatelessWidget {
  const _LocationsView({
    required this.locations,
    required this.repository,
    required this.onRefresh,
  });

  final List<AllowedLocation> locations;
  final InventoryRepository repository;
  final Future<void> Function() onRefresh;

  Future<void> _openEditor(BuildContext context, {AllowedLocation? location}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _LocationEditorDialog(repository: repository, location: location),
    );
    await onRefresh();
  }

  Future<void> _deleteLocation(BuildContext context, AllowedLocation location) async {
    await repository.deleteLocation(location.id);
    await onRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${location.code} deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: _PageHeader(
                title: 'Locations',
                subtitle: 'Manage allowed lines and racks so users only choose valid destinations.',
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add line or rack'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Allowed locations',
          child: Column(
            children: locations.map((location) {
              return _CrudRow(
                title: location.code,
                subtitle: location.type == LocationType.line ? 'Line destination' : 'Rack destination',
                trailing: location.isActive ? 'Active' : 'Inactive',
                onEdit: () => _openEditor(context, location: location),
                onDelete: () => _deleteLocation(context, location),
              );
            }).toList(),
          ),
        ),
        ],
      ),
    );
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView({
    required this.users,
    required this.repository,
    required this.onRefresh,
  });

  final List<AppUser> users;
  final InventoryRepository repository;
  final Future<void> Function() onRefresh;

  Future<void> _openEditor(BuildContext context, {AppUser? user}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _UserEditorDialog(repository: repository, user: user),
    );
    await onRefresh();
  }

  Future<void> _deleteUser(BuildContext context, AppUser user) async {
    await repository.deleteUser(user.id);
    await onRefresh();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: _PageHeader(
                title: 'Users',
                subtitle: 'Control who can use the system and what role they have in the equipment-room workflow.',
              ),
            ),
            FilledButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add user'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Registered users',
          child: Column(
            children: users.map((user) {
              return _CrudRow(
                title: user.name,
                subtitle: '${user.badgeId} • ${_roleLabel(user.role)}',
                trailing: user.isActive ? 'Active' : 'Inactive',
                onEdit: () => _openEditor(context, user: user),
                onDelete: () => _deleteUser(context, user),
              );
            }).toList(),
          ),
        ),
        ],
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.operator:
        return 'Operator';
      case UserRole.viewer:
        return 'Viewer';
    }
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({
    required this.pairingSession,
  });

  final PairingSession? pairingSession;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
        const _PageHeader(
          title: 'Settings',
          subtitle: 'Operational controls and policies for the equipment-room terminal.',
        ),
        const SizedBox(height: 16),
        const _Panel(
          title: 'Recommended policies',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('• Desktop confirmation only for borrow and return'),
              SizedBox(height: 8),
              Text('• Phone pairing sessions should be short-lived'),
              SizedBox(height: 8),
              Text('• Use only allowed lines and racks from the managed location list'),
              SizedBox(height: 8),
              Text('• Later, register the equipment-room PC as the only trusted transactional device'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Current session state',
          child: Text(
            pairingSession == null
                ? 'No active phone pairing session.'
                : 'Pair code ${pairingSession!.code} is active. Connected device: ${pairingSession!.connectedDeviceName ?? 'waiting'}',
          ),
        ),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF183A37))),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(color: isDark ? const Color(0xFF9FA8BF) : _softText, height: 1.5)),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.onBorrowTap,
    required this.onReturnTap,
  });

  final VoidCallback onBorrowTap;
  final VoidCallback onReturnTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFFDFDFF)],
        ),
        border: Border.all(color: isDark ? const Color(0xFF252B42) : _cardBorder),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x142C3350),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Equipment-room control desk', style: TextStyle(color: isDark ? Colors.white : _titleText, fontSize: 30, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
            'The official desktop flow keeps transactions fast while preventing remote fake borrowing and incorrect location entry.',
            style: TextStyle(color: isDark ? const Color(0xFF9FA8BF) : _softText, height: 1.5),
          ),
          const SizedBox(height: 18),
          Container(
            constraints: const BoxConstraints(minHeight: 176),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFFF4F1FF), Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: 18),
                _HeroMetric(
                  title: 'Items ready',
                  value: '128',
                  icon: Icons.inventory_2_rounded,
                ),
                const SizedBox(width: 12),
                _HeroMetric(
                  title: 'Scans today',
                  value: '42',
                  icon: Icons.qr_code_scanner_rounded,
                ),
                const SizedBox(width: 12),
                _HeroMetric(
                  title: 'Active pair',
                  value: '01',
                  icon: Icons.phonelink_ring_rounded,
                ),
                const SizedBox(width: 18),
              ],
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
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
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
                    foregroundColor: _accent,
                    side: const BorderSide(color: Color(0xFFDADCF0)),
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF252B42) : _cardBorder),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x142C3350),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Phone pairing', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _titleText)),
          const SizedBox(height: 8),
          const Text(
            'A phone may scan for this PC session, but final approval stays here.',
            style: TextStyle(height: 1.5, color: _softText),
          ),
          const SizedBox(height: 18),
          if (session == null)
            FilledButton.icon(
              onPressed: onStartPairing,
              icon: const Icon(Icons.phonelink_setup_rounded),
              label: const Text('Create pairing session'),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Session code: ${session!.code}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 8),
                Text(session!.status == PairingSessionStatus.connected
                    ? 'Connected phone: ${session!.connectedDeviceName ?? 'Unknown device'}'
                    : 'Waiting for a phone to connect'),
                const SizedBox(height: 8),
                Text('Last scan from phone: ${session!.lastScannedQr ?? '-'}'),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFECEEFA)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(
              radius: 22,
              backgroundColor: _accentSoft,
              foregroundColor: _accent,
              child: Icon(icon),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _titleText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: _softText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? const Color(0xFF252B42) : _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 6),
          Text(title),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF252B42) : _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String description;
  final String actionLabel;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow(this.record);

  final MovementRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${record.itemName} • ${record.fromLocation} -> ${record.toLocation}',
              style: const TextStyle(color: _titleText, fontWeight: FontWeight.w600),
            ),
          ),
          Text(record.actorName, style: const TextStyle(color: _softText)),
        ],
      ),
    );
  }
}

class _DetailedMovementRow extends StatelessWidget {
  const _DetailedMovementRow(this.record);

  final MovementRecord record;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(record.itemName, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('QR ${record.itemQrCode}'),
          const SizedBox(height: 4),
          Text('${record.fromLocation} -> ${record.toLocation}'),
          const SizedBox(height: 4),
          Text('${record.actorName} • ${formatter.format(record.createdAt)}'),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow(this.item);

  final Item item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${item.name} • ${item.qrCode} • ${item.currentLocation}',
              style: const TextStyle(color: _titleText, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: item.status == ItemStatus.available
                  ? const Color(0x2216C098)
                  : const Color(0x22EA5455),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.status == ItemStatus.available ? 'Ready' : 'Borrowed',
              style: TextStyle(
                color: item.status == ItemStatus.available ? _success : _danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrudRow extends StatelessWidget {
  const _CrudRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: trailing == 'Active' || trailing == 'Ready'
                  ? const Color(0x2216C098)
                  : trailing == 'Borrowed' || trailing == 'Inactive'
                      ? const Color(0x22EA5455)
                      : const Color(0x225B39EA),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailing,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: trailing == 'Active' || trailing == 'Ready'
                    ? _success
                    : trailing == 'Borrowed' || trailing == 'Inactive'
                        ? _danger
                        : _accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
    );
  }
}

class _ItemEditorDialog extends StatefulWidget {
  const _ItemEditorDialog({
    required this.repository,
    this.item,
  });

  final InventoryRepository repository;
  final Item? item;

  @override
  State<_ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<_ItemEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _qrController;
  late final TextEditingController _categoryController;
  late final TextEditingController _locationController;
  late ItemStatus _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _qrController = TextEditingController(text: widget.item?.qrCode ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _locationController = TextEditingController(text: widget.item?.currentLocation ?? '');
    _status = widget.item?.status ?? ItemStatus.available;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qrController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final item = Item(
      id: widget.item?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      qrCode: _qrController.text.trim(),
      name: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      currentLocation: _locationController.text.trim(),
      status: _status,
      lastBorrowerName: widget.item?.lastBorrowerName,
    );

    if (widget.item == null) {
      await widget.repository.addItem(item);
    } else {
      await widget.repository.updateItem(item);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Register item' : 'Edit item'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DialogField(controller: _nameController, label: 'Item name'),
            const SizedBox(height: 10),
            _DialogField(controller: _qrController, label: 'QR code'),
            const SizedBox(height: 10),
            _DialogField(controller: _categoryController, label: 'Category'),
            const SizedBox(height: 10),
            _DialogField(controller: _locationController, label: 'Current location'),
            const SizedBox(height: 10),
            DropdownButtonFormField<ItemStatus>(
              value: _status,
              items: const <DropdownMenuItem<ItemStatus>>[
                DropdownMenuItem(value: ItemStatus.available, child: Text('Available')),
                DropdownMenuItem(value: ItemStatus.borrowed, child: Text('Borrowed')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _status = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _LocationEditorDialog extends StatefulWidget {
  const _LocationEditorDialog({
    required this.repository,
    this.location,
  });

  final InventoryRepository repository;
  final AllowedLocation? location;

  @override
  State<_LocationEditorDialog> createState() => _LocationEditorDialogState();
}

class _LocationEditorDialogState extends State<_LocationEditorDialog> {
  late final TextEditingController _codeController;
  late LocationType _type;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.location?.code ?? '');
    _type = widget.location?.type ?? LocationType.line;
    _isActive = widget.location?.isActive ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final location = AllowedLocation(
      id: widget.location?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      code: _codeController.text.trim().toUpperCase(),
      type: _type,
      isActive: _isActive,
    );

    if (widget.location == null) {
      await widget.repository.addLocation(location);
    } else {
      await widget.repository.updateLocation(location);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.location == null ? 'Add location' : 'Edit location'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DialogField(controller: _codeController, label: 'Location code'),
            const SizedBox(height: 10),
            DropdownButtonFormField<LocationType>(
              value: _type,
              items: const <DropdownMenuItem<LocationType>>[
                DropdownMenuItem(value: LocationType.line, child: Text('Line')),
                DropdownMenuItem(value: LocationType.rack, child: Text('Rack')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _type = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _UserEditorDialog extends StatefulWidget {
  const _UserEditorDialog({
    required this.repository,
    this.user,
  });

  final InventoryRepository repository;
  final AppUser? user;

  @override
  State<_UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<_UserEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _badgeController;
  late final TextEditingController _passwordController;
  late UserRole _role;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _badgeController = TextEditingController(text: widget.user?.badgeId ?? '');
    _passwordController = TextEditingController(text: widget.user?.password ?? '');
    _role = widget.user?.role ?? UserRole.operator;
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _badgeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = AppUser(
      id: widget.user?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      badgeId: _badgeController.text.trim().toUpperCase(),
      password: _passwordController.text,
      role: _role,
      isActive: _isActive,
    );

    if (widget.user == null) {
      await widget.repository.addUser(user);
    } else {
      await widget.repository.updateUser(user);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.user == null ? 'Add user' : 'Edit user'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _DialogField(controller: _nameController, label: 'Full name'),
            const SizedBox(height: 10),
            _DialogField(controller: _badgeController, label: 'Badge ID'),
            const SizedBox(height: 10),
            _DialogField(controller: _passwordController, label: 'Password'),
            const SizedBox(height: 10),
            DropdownButtonFormField<UserRole>(
              value: _role,
              items: const <DropdownMenuItem<UserRole>>[
                DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                DropdownMenuItem(value: UserRole.operator, child: Text('Operator')),
                DropdownMenuItem(value: UserRole.viewer, child: Text('Viewer')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _role = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) {
                setState(() {
                  _isActive = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F8F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
