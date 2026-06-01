import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/inventory_repository.dart';
import '../../models/allowed_location.dart';
import '../../models/app_user.dart';
import '../../models/item.dart';
import '../../models/item_category.dart';
import '../../models/movement_record.dart';
import '../../models/pairing_session.dart';
import '../../services/inventory_report_service.dart';
import '../scan/scan_screen.dart';
import '../workflow/action_flow_screen.dart';
import '../workflow/transaction_queue_screen.dart';

part 'desktop_dashboard_overview_page.dart';
part 'desktop_borrow_page.dart';
part 'desktop_return_page.dart';
part 'desktop_reports_page.dart';
part 'desktop_history_page.dart';
part 'desktop_items_page.dart';
part 'desktop_categories_page.dart';
part 'desktop_locations_page.dart';
part 'desktop_users_page.dart';
part 'desktop_roles_page.dart';
part 'desktop_settings_page.dart';
part 'desktop_pairing_dialog.dart';
part 'item_editor_dialog.dart';
part 'category_editor_dialog.dart';
part 'location_editor_dialog.dart';
part 'user_editor_dialog.dart';
part 'user_self_settings_dialog.dart';
part 'item_history_dialog.dart';
part 'role_editor_dialog.dart';
part 'desktop_section_header.dart';
part 'desktop_panel.dart';
part 'desktop_metric_card.dart';
part 'desktop_status_chip.dart';
part 'desktop_simple_tile.dart';
part 'desktop_shell_screen_v2_shell_widgets.dart';

enum DesktopMenuV2 {
  dashboard,
  borrow,
  returnItem,
  reports,
  history,
  items,
  categories,
  locations,
  roles,
  users,
  settings,
}

class DesktopShellScreen extends StatefulWidget {
  const DesktopShellScreen({
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
  State<DesktopShellScreen> createState() => _DesktopShellScreenState();
}

class _DesktopShellScreenState extends State<DesktopShellScreen> {
  DesktopMenuV2 _selectedMenu = DesktopMenuV2.dashboard;
  bool _isSidebarCollapsed = false;
  bool _isLoading = true;
  String? _loadError;
  PairingSession? _pairingSession;
  Timer? _pairingPoller;
  List<Item> _items = <Item>[];
  List<MovementRecord> _movements = <MovementRecord>[];
  List<AllowedLocation> _locations = <AllowedLocation>[];
  List<ItemCategory> _categories = <ItemCategory>[];
  List<AppUser> _users = <AppUser>[];
  final List<_RoleDefinition> _roles = <_RoleDefinition>[
    const _RoleDefinition(
      name: 'Admin',
      permissions: <String>['Dashboard', 'Borrow', 'Return', 'Reports', 'History', 'Items', 'Categories', 'Locations', 'Roles', 'Users'],
    ),
    const _RoleDefinition(
      name: 'Operator',
      permissions: <String>['Dashboard', 'Borrow', 'Return', 'Reports', 'History', 'Items'],
    ),
    const _RoleDefinition(
      name: 'Viewer',
      permissions: <String>['Dashboard', 'Reports', 'History'],
    ),
  ];
  String? _lastAutoOpenedPairSignature;
  bool _isTransactionScreenOpen = false;
  late AppUser _displayUser;

  List<DesktopMenuV2> get _visibleMenus => <DesktopMenuV2>[
        DesktopMenuV2.dashboard,
        DesktopMenuV2.borrow,
        DesktopMenuV2.returnItem,
        DesktopMenuV2.reports,
        DesktopMenuV2.history,
        DesktopMenuV2.items,
        DesktopMenuV2.categories,
        DesktopMenuV2.locations,
        if (widget.currentUser.role == UserRole.admin) DesktopMenuV2.roles,
        if (widget.currentUser.role == UserRole.admin) DesktopMenuV2.users,
      ];

  @override
  void initState() {
    super.initState();
    _displayUser = widget.currentUser;
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.repository.getItems();
      final movements = await widget.repository.getRecentMovements();
      final locations = await widget.repository.getAllowedLocations();
      final categories = await widget.repository.getCategories();
      final users = await widget.repository.getUsers();
      if (!mounted) return;
      setState(() {
        _items = items;
        _movements = movements;
        _locations = locations;
        _categories = categories;
        _users = users;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _startPairing() async {
    final session = _pairingSession ?? await widget.repository.createPairingSession();
    if (!mounted) return;
    setState(() {
      _pairingSession = session;
    });
    _startPairingPolling();
    await _openPairingDialog(session);
  }

  String _pairingPayload(String code) {
    return 'factory-monitoring://pair?code=$code';
  }

  void _startPairingPolling() {
    _pairingPoller?.cancel();
    final code = _pairingSession?.code;
    if (code == null || code.isEmpty) return;

    _pairingPoller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshPairingSession(),
    );
  }

  Future<void> _refreshPairingSession() async {
    final code = _pairingSession?.code;
    if (code == null || code.isEmpty) return;

    final session = await widget.repository.getPairingSession(code);
    if (!mounted || session == null) return;
    setState(() {
      _pairingSession = session;
    });
    await _handlePairingAction(session);
  }

  Future<void> _handlePairingAction(PairingSession session) async {
    if (session.activeMode == null) {
      _lastAutoOpenedPairSignature = null;
      return;
    }
    if (_isTransactionScreenOpen) return;

    final signature = '${session.activeMode}:${session.pendingScans.map((entry) => entry.qrCode).join('|')}';
    if (_lastAutoOpenedPairSignature == signature) return;
    _lastAutoOpenedPairSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (session.activeMode == PairActionMode.registerItem) {
        final entry = session.pendingScans.isEmpty ? null : session.pendingScans.last;
        if (entry == null) return;
        await _openItemEditor(
          initialQrCode: entry.qrCode,
          consumePairingScan: true,
        );
        return;
      }

      await _openTransaction(
        session.activeMode == PairActionMode.borrow ? WorkflowMode.borrow : WorkflowMode.returnItem,
      );
    });
  }

  Future<void> _openPairingDialog(PairingSession session) async {
    await showDialog<void>(
      context: context,
      builder: (_) => DesktopPairingDialog(
        repository: widget.repository,
        initialSession: session,
        payloadBuilder: _pairingPayload,
        onSessionChanged: (updatedSession) {
          if (!mounted) return;
          setState(() {
            _pairingSession = updatedSession;
          });
        },
      ),
    );
  }

  Future<void> _openTransaction(WorkflowMode mode) async {
    if (_isTransactionScreenOpen) return;
    _isTransactionScreenOpen = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransactionQueueScreen(
          repository: widget.repository,
          mode: mode,
          currentUser: widget.currentUser,
          pairingSession: _pairingSession,
        ),
      ),
    );
    _isTransactionScreenOpen = false;
    await _load();
  }

  Future<void> _openItemEditor({
    Item? item,
    String? initialQrCode,
    bool consumePairingScan = false,
  }) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ItemEditorDialog(
        repository: widget.repository,
        item: item,
        categories: _categories,
        locations: _locations,
        initialQrCode: initialQrCode,
      ),
    );
    if (saved == true && consumePairingScan && initialQrCode != null && _pairingSession != null) {
      _pairingSession = await widget.repository.consumePairingScan(
        sessionCode: _pairingSession!.code,
        qrCode: initialQrCode,
      );
    }
    await _load();
  }

  Future<void> _disconnectPairing() async {
    final session = _pairingSession;
    if (session == null) return;
    final cleared = await widget.repository.disconnectPairingSession(
      sessionCode: session.code,
    );
    if (!mounted) return;
    setState(() {
      _pairingSession = cleared;
      _lastAutoOpenedPairSignature = null;
    });
  }

  Future<void> _deleteItem(Item item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Delete ${item.name} (${item.qrCode}) from the item list?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await widget.repository.deleteItem(item.id);
    await _load();
  }

  Future<void> _openItemHistory(Item item) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ItemHistoryDialog(
        item: item,
        movements: _movements.where((movement) => movement.itemQrCode == item.qrCode).toList(),
      ),
    );
  }

  Future<void> _openCategoryEditor({ItemCategory? category}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CategoryEditorDialog(
        repository: widget.repository,
        category: category,
      ),
    );
    await _load();
  }

  Future<void> _deleteCategory(ItemCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Delete ${category.name}?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.deleteCategory(category.id);
    await _load();
  }

  Future<void> _openRoleEditor() async {
    final role = await showDialog<_RoleDefinition>(
      context: context,
      builder: (_) => const RoleEditorDialog(),
    );

    if (role == null || !mounted) return;
    setState(() {
      _roles.add(role);
    });
  }

  Future<void> _openLocationEditor({AllowedLocation? location}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => LocationEditorDialog(repository: widget.repository, location: location),
    );
    await _load();
  }

  Future<void> _deleteLocation(AllowedLocation location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete location'),
        content: Text('Delete ${location.code}?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.deleteLocation(location.id);
    await _load();
  }

  Future<void> _openUserEditor({AppUser? user}) async {
    await showDialog<void>(
      context: context,
      builder: (_) => UserEditorDialog(
        repository: widget.repository,
        user: user,
        roleOptions: _roles.map((role) => role.name).toList(),
      ),
    );
    await _load();
  }

  Future<void> _deleteUser(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Delete ${user.name} (${user.badgeId})?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.deleteUser(user.id);
    await _load();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out from terminal?'),
        content: const Text(
          'This will return the desktop app to the equipment-room sign in screen.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      widget.onLogout();
    }
  }

  Future<void> _openProfileMenu() async {
    final selection = await showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 88, 24, 0),
      items: <PopupMenuEntry<String>>[
        if (_displayUser.role != UserRole.admin)
          const PopupMenuItem<String>(
            value: 'settings',
            child: Text('User settings'),
          ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text('Log out'),
        ),
      ],
    );

    if (!mounted || selection == null) return;
    if (selection == 'logout') {
      await _confirmLogout();
      return;
    }
    if (selection == 'settings') {
      await _openUserSettings();
    }
  }

  Future<void> _openUserSettings() async {
    final updatedUser = await showDialog<AppUser>(
      context: context,
      builder: (_) => UserSelfSettingsDialog(user: _displayUser),
    );

    if (updatedUser == null) return;
    await widget.repository.updateUser(updatedUser);
    if (!mounted) return;
    setState(() {
      _displayUser = updatedUser;
    });
    await _load();
  }

  @override
  void dispose() {
    _pairingPoller?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F1220) : const Color(0xFFF7F8FC);
    final sidebarBg = isDark ? const Color(0xFF151A2B) : const Color(0xFFFFFFFF);
    final sidebarWidth = _isSidebarCollapsed ? 104.0 : 298.0;

    return Scaffold(
      body: Row(
        children: <Widget>[
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(
                right: BorderSide(
                  color: isDark ? const Color(0xFF202741) : const Color(0xFFE8ECF5),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(_isSidebarCollapsed ? 10 : 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF6D52F5), Color(0xFF4E35D8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF5B39EA).withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _isSidebarCollapsed
                      ? Column(
                          children: <Widget>[
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isSidebarCollapsed = false;
                                });
                              },
                              icon: const Icon(Icons.menu_open_rounded, color: Colors.white),
                              tooltip: 'Expand sidebar',
                            ),
                            const SizedBox(height: 12),
                            const CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0x33FFFFFF),
                              child: Text(
                                'M',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            IconButton(
                              onPressed: widget.onToggleTheme,
                              icon: Icon(
                                widget.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Toggle theme',
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'Monitoring hub',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          height: 1.05,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                                        style: const TextStyle(
                                          color: Color(0xFFE9E2FF),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: <Widget>[
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isSidebarCollapsed = true;
                                        });
                                      },
                                      icon: const Icon(Icons.menu_open_rounded, color: Colors.white),
                                      tooltip: 'Collapse sidebar',
                                    ),
                                    IconButton(
                                      onPressed: widget.onToggleTheme,
                                      icon: Icon(
                                        widget.themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                        color: Colors.white,
                                      ),
                                      tooltip: 'Toggle theme',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                children: <Widget>[
                                  Icon(Icons.space_dashboard_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Desktop control center',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                if (!_isSidebarCollapsed)
                  Text(
                    'MAIN MENU',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9FA8BF) : const Color(0xFF9197B3),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                if (!_isSidebarCollapsed) const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: _visibleMenus
                          .map((menu) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _SidebarItem(
                                  selected: _selectedMenu == menu,
                                  label: _menuLabel(menu),
                                  icon: _menuIcon(menu),
                                  collapsed: _isSidebarCollapsed,
                                  onTap: () {
                                    setState(() {
                                      _selectedMenu = menu;
                                    });
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _isSidebarCollapsed
                    ? Center(
                        child: IconButton(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout_rounded),
                          tooltip: 'Log out',
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: _confirmLogout,
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log out'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          alignment: Alignment.centerLeft,
                          side: BorderSide(
                            color: isDark ? const Color(0xFF303854) : const Color(0xFFD8DDEA),
                          ),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF1F2533),
                        ),
                      ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: bg,
              padding: const EdgeInsets.fromLTRB(24, 24, 28, 28),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadError != null
                      ? _LoadErrorState(
                          message: _loadError!,
                          onRetry: _load,
                        )
                      : Column(
                          children: <Widget>[
                            _DesktopTopBar(
                              pageTitle: _menuLabel(_selectedMenu),
                              user: _displayUser,
                              onOpenProfileMenu: _openProfileMenu,
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1400),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF151A2B) : const Color(0xFFFFFFFF),
                                      borderRadius: BorderRadius.circular(32),
                                      border: Border.all(
                                        color: isDark ? const Color(0xFF232A43) : const Color(0xFFE6EBF4),
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
                                          blurRadius: 30,
                                          offset: const Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: _buildContent(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }

  String _menuLabel(DesktopMenuV2 menu) {
    switch (menu) {
      case DesktopMenuV2.dashboard:
        return 'Dashboard';
      case DesktopMenuV2.borrow:
        return 'Borrow';
      case DesktopMenuV2.returnItem:
        return 'Return';
      case DesktopMenuV2.reports:
        return 'Reports';
      case DesktopMenuV2.history:
        return 'History';
      case DesktopMenuV2.items:
        return 'Items';
      case DesktopMenuV2.categories:
        return 'Categories';
      case DesktopMenuV2.locations:
        return 'Locations';
      case DesktopMenuV2.roles:
        return 'Roles';
      case DesktopMenuV2.users:
        return 'Users';
      case DesktopMenuV2.settings:
        return 'Settings';
    }
  }

  IconData _menuIcon(DesktopMenuV2 menu) {
    switch (menu) {
      case DesktopMenuV2.dashboard:
        return Icons.dashboard_rounded;
      case DesktopMenuV2.borrow:
        return Icons.call_made_rounded;
      case DesktopMenuV2.returnItem:
        return Icons.assignment_return_rounded;
      case DesktopMenuV2.reports:
        return Icons.analytics_rounded;
      case DesktopMenuV2.history:
        return Icons.history_rounded;
      case DesktopMenuV2.items:
        return Icons.inventory_2_rounded;
      case DesktopMenuV2.categories:
        return Icons.category_rounded;
      case DesktopMenuV2.locations:
        return Icons.grid_view_rounded;
      case DesktopMenuV2.roles:
        return Icons.shield_rounded;
      case DesktopMenuV2.users:
        return Icons.people_alt_rounded;
      case DesktopMenuV2.settings:
        return Icons.settings_rounded;
    }
  }

  Widget _buildContent(BuildContext context) {
    final canTransact = widget.currentUser.role == UserRole.admin || widget.currentUser.role == UserRole.operator;
    final canManage = widget.currentUser.role == UserRole.admin;
    switch (_selectedMenu) {
      case DesktopMenuV2.dashboard:
        return DesktopDashboardOverviewPage(
          items: _items,
          users: _users,
          locations: _locations,
          movements: _movements,
          pairingSession: _pairingSession,
          onStartPairing: _startPairing,
          onDisconnectPairing: _disconnectPairing,
          onBorrow: canTransact ? () => _openTransaction(WorkflowMode.borrow) : null,
          onReturn: canTransact ? () => _openTransaction(WorkflowMode.returnItem) : null,
          userRole: widget.currentUser.role,
          onEditItem: canManage ? _openItemEditor : null,
          onDeleteItem: canManage ? _deleteItem : null,
          onViewItemHistory: _openItemHistory,
        );
      case DesktopMenuV2.borrow:
        return DesktopBorrowPage(
          pairingSession: _pairingSession,
          onBorrow: canTransact ? () => _openTransaction(WorkflowMode.borrow) : null,
          role: widget.currentUser.role,
        );
      case DesktopMenuV2.returnItem:
        return DesktopReturnPage(
          pairingSession: _pairingSession,
          onReturn: canTransact ? () => _openTransaction(WorkflowMode.returnItem) : null,
          role: widget.currentUser.role,
        );
      case DesktopMenuV2.reports:
        return DesktopReportsPage(
          items: _items,
          movements: _movements,
          users: _users,
        );
      case DesktopMenuV2.history:
        return DesktopHistoryPage(movements: _movements);
      case DesktopMenuV2.items:
        return DesktopItemsPage(
          items: _items,
          canManage: canManage,
          onAdd: () => _openItemEditor(),
          onEdit: _openItemEditor,
          onDelete: _deleteItem,
          onViewHistory: _openItemHistory,
        );
      case DesktopMenuV2.categories:
        return DesktopCategoriesPage(
          categories: _categories,
          canManage: canManage,
          onAdd: () => _openCategoryEditor(),
          onEdit: _openCategoryEditor,
          onDelete: _deleteCategory,
        );
      case DesktopMenuV2.locations:
        return DesktopLocationsPage(
          locations: _locations,
          canManage: canManage,
          onAdd: () => _openLocationEditor(),
          onEdit: _openLocationEditor,
          onDelete: _deleteLocation,
        );
      case DesktopMenuV2.roles:
        return _DesktopRolesPage(
          roles: _roles,
          onAddRole: _openRoleEditor,
        );
      case DesktopMenuV2.users:
        return DesktopUsersPage(
          users: _users,
          canManage: canManage,
          onAdd: () => _openUserEditor(),
          onEdit: _openUserEditor,
          onDelete: _deleteUser,
        );
      case DesktopMenuV2.settings:
        return DesktopSettingsPage(
          pairingSession: _pairingSession,
          themeMode: widget.themeMode,
          currentUser: widget.currentUser,
          onLogout: _confirmLogout,
        );
    }
  }
}
