import '../models/allowed_location.dart';
import '../models/app_user.dart';
import '../models/item.dart';
import '../models/item_category.dart';
import '../models/movement_record.dart';
import '../models/pairing_session.dart';
import 'inventory_repository.dart';

class MockInventoryRepository implements InventoryRepository {
  MockInventoryRepository({
    required List<Item> items,
    required List<MovementRecord> movements,
    required List<AllowedLocation> locations,
    required List<ItemCategory> categories,
    required List<AppUser> users,
  })  : _items = items,
        _movements = movements,
        _locations = locations,
        _categories = categories,
        _users = users;

  factory MockInventoryRepository.seeded() {
    return MockInventoryRepository(
      items: <Item>[
        const Item(
          id: '1',
          qrCode: 'EQ-0001',
          name: 'Torque Wrench',
          category: 'Mechanical',
          currentLocation: 'RACK 2B',
          status: ItemStatus.available,
        ),
        const Item(
          id: '2',
          qrCode: 'EQ-0002',
          name: 'Digital Caliper',
          category: 'Measurement',
          currentLocation: 'LINE 6',
          status: ItemStatus.borrowed,
          lastBorrowerName: 'Rizky',
        ),
        const Item(
          id: '3',
          qrCode: 'EQ-0003',
          name: 'Safety Clamp',
          category: 'Fixture',
          currentLocation: 'RACK 5A',
          status: ItemStatus.available,
        ),
      ],
      movements: <MovementRecord>[
        MovementRecord(
          id: 'm1',
          itemName: 'Digital Caliper',
          itemQrCode: 'EQ-0002',
          action: MovementAction.borrow,
          actorName: 'Rizky',
          fromLocation: 'RACK 1C',
          toLocation: 'LINE 6',
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
        ),
        MovementRecord(
          id: 'm2',
          itemName: 'Torque Wrench',
          itemQrCode: 'EQ-0001',
          action: MovementAction.returnItem,
          actorName: 'Andi',
          fromLocation: 'LINE 2',
          toLocation: 'RACK 2B',
          createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
        ),
      ],
      locations: <AllowedLocation>[
        ...List<AllowedLocation>.generate(
          10,
          (index) => AllowedLocation(
            id: 'line-${index + 1}',
            code: 'LINE ${index + 1}',
            type: LocationType.line,
            isActive: true,
          ),
        ),
        ...<AllowedLocation>[
          const AllowedLocation(id: 'rack-1a', code: 'RACK 1A', type: LocationType.rack, isActive: true),
          const AllowedLocation(id: 'rack-1b', code: 'RACK 1B', type: LocationType.rack, isActive: true),
          const AllowedLocation(id: 'rack-1c', code: 'RACK 1C', type: LocationType.rack, isActive: true),
          const AllowedLocation(id: 'rack-2a', code: 'RACK 2A', type: LocationType.rack, isActive: true),
          const AllowedLocation(id: 'rack-2b', code: 'RACK 2B', type: LocationType.rack, isActive: true),
          const AllowedLocation(id: 'rack-2c', code: 'RACK 2C', type: LocationType.rack, isActive: true),
          const AllowedLocation(id: 'rack-3a', code: 'RACK 3A', type: LocationType.rack, isActive: true),
          const AllowedLocation(id: 'rack-3b', code: 'RACK 3B', type: LocationType.rack, isActive: true),
          const AllowedLocation(id: 'rack-3c', code: 'RACK 3C', type: LocationType.rack, isActive: true),
        ],
      ],
      categories: const <ItemCategory>[
        ItemCategory(id: 'cat-mech', name: 'Mechanical', isActive: true),
        ItemCategory(id: 'cat-measure', name: 'Measurement', isActive: true),
        ItemCategory(id: 'cat-fixture', name: 'Fixture', isActive: true),
      ],
      users: const <AppUser>[
        AppUser(id: 'u1', name: 'Christhian', badgeId: 'ADM001', password: 'admin123', role: UserRole.admin, isActive: true),
        AppUser(id: 'u2', name: 'Budi', badgeId: 'OPR014', password: 'operator123', role: UserRole.operator, isActive: true),
        AppUser(id: 'u3', name: 'Sinta', badgeId: 'USR022', password: 'viewer123', role: UserRole.viewer, isActive: true),
      ],
    );
  }

  final List<Item> _items;
  final List<MovementRecord> _movements;
  final List<AllowedLocation> _locations;
  final List<ItemCategory> _categories;
  final List<AppUser> _users;
  PairingSession? _pairingSession;

  @override
  Future<void> addItem(Item item) async {
    _items.insert(0, item);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    _items.removeWhere((item) => item.id == itemId);
  }

  @override
  Future<void> borrowItem({
    required Item item,
    required String borrowerName,
    required String destinationLine,
    String? description,
  }) async {
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index == -1) return;

    final updatedItem = item.copyWith(
      currentLocation: destinationLine,
      status: ItemStatus.borrowed,
      lastBorrowerName: borrowerName,
    );

    _items[index] = updatedItem;
    _movements.insert(
      0,
      MovementRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: item.name,
        itemQrCode: item.qrCode,
        action: MovementAction.borrow,
        actorName: borrowerName,
        fromLocation: item.currentLocation,
        toLocation: destinationLine,
        createdAt: DateTime.now(),
        description: description,
      ),
    );
  }

  @override
  Future<Item?> findItemByQr(String qrCode) async {
    try {
      return _items.firstWhere((item) => item.qrCode.toUpperCase() == qrCode.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Item>> getItems() async {
    return List<Item>.from(_items);
  }

  @override
  Future<List<AllowedLocation>> getAllowedLocations() async {
    return List<AllowedLocation>.from(_locations);
  }

  @override
  Future<List<MovementRecord>> getRecentMovements() async {
    return List<MovementRecord>.from(_movements);
  }

  @override
  Future<List<AppUser>> getUsers() async {
    return List<AppUser>.from(_users);
  }

  @override
  Future<List<ItemCategory>> getCategories() async {
    return List<ItemCategory>.from(_categories);
  }

  @override
  Future<void> addCategory(ItemCategory category) async {
    _categories.add(category);
  }

  @override
  Future<void> updateCategory(ItemCategory category) async {
    final index = _categories.indexWhere((element) => element.id == category.id);
    if (index == -1) return;
    _categories[index] = category;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((category) => category.id == categoryId);
  }

  @override
  Future<AppUser?> authenticate({
    required String badgeId,
    required String password,
  }) async {
    try {
      return _users.firstWhere(
        (user) =>
            user.isActive &&
            user.badgeId.toUpperCase() == badgeId.toUpperCase() &&
            user.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateItem(Item item) async {
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index == -1) return;
    _items[index] = item;
  }

  @override
  Future<void> addLocation(AllowedLocation location) async {
    _locations.add(location);
  }

  @override
  Future<void> updateLocation(AllowedLocation location) async {
    final index = _locations.indexWhere((element) => element.id == location.id);
    if (index == -1) return;
    _locations[index] = location;
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    _locations.removeWhere((location) => location.id == locationId);
  }

  @override
  Future<void> addUser(AppUser user) async {
    _users.add(user);
  }

  @override
  Future<void> updateUser(AppUser user) async {
    final index = _users.indexWhere((element) => element.id == user.id);
    if (index == -1) return;
    _users[index] = user;
  }

  @override
  Future<void> deleteUser(String userId) async {
    _users.removeWhere((user) => user.id == userId);
  }

  @override
  Future<PairingSession> createPairingSession() async {
    _pairingSession = const PairingSession(
      code: 'EQROOM-2417',
      status: PairingSessionStatus.waitingForPhone,
      pendingScans: <PairingScanEntry>[],
    );
    return _pairingSession!;
  }

  @override
  Future<PairingSession?> getPairingSession(String sessionCode) async {
    if (_pairingSession?.code == sessionCode) {
      return _pairingSession;
    }
    return null;
  }

  @override
  Future<PairingSession> setPairingMode({
    required String sessionCode,
    required PairActionMode mode,
  }) async {
    final session = await getPairingSession(sessionCode);
    if (session == null) {
      throw Exception('Pairing session not found.');
    }

    _pairingSession = session.copyWith(
      status: PairingSessionStatus.connected,
      activeMode: mode,
    );
    return _pairingSession!;
  }

  @override
  Future<PairingSession> connectPhoneToSession({
    required String sessionCode,
    required String deviceName,
  }) async {
    final session = await getPairingSession(sessionCode);
    if (session == null) {
      throw Exception('Pairing session not found.');
    }

    _pairingSession = session.copyWith(
      status: PairingSessionStatus.connected,
      connectedDeviceName: deviceName,
    );
    return _pairingSession!;
  }

  @override
  Future<PairingSession> submitPhoneScan({
    required String sessionCode,
    required String qrCode,
    required PairActionMode mode,
  }) async {
    final session = await getPairingSession(sessionCode);
    if (session == null) {
      throw Exception('Pairing session not found.');
    }

    final nextScans = <PairingScanEntry>[
      ...session.pendingScans.where((entry) => entry.qrCode.toUpperCase() != qrCode.toUpperCase()),
      PairingScanEntry(
        qrCode: qrCode,
        mode: mode,
        scannedAt: DateTime.now(),
        scannedBy: session.connectedDeviceName,
      ),
    ];

    _pairingSession = session.copyWith(
      status: PairingSessionStatus.scanned,
      lastScannedQr: qrCode,
      activeMode: mode,
      pendingScans: nextScans,
    );
    return _pairingSession!;
  }

  @override
  Future<PairingSession> consumePairingScan({
    required String sessionCode,
    required String qrCode,
  }) async {
    final session = await getPairingSession(sessionCode);
    if (session == null) {
      throw Exception('Pairing session not found.');
    }

    final nextScans = session.pendingScans
        .where((entry) => entry.qrCode.toUpperCase() != qrCode.toUpperCase())
        .toList();

    _pairingSession = PairingSession(
      code: session.code,
      status: nextScans.isEmpty ? PairingSessionStatus.connected : PairingSessionStatus.scanned,
      connectedDeviceName: session.connectedDeviceName,
      lastScannedQr: nextScans.isEmpty ? null : nextScans.last.qrCode,
      activeMode: nextScans.isEmpty ? null : nextScans.last.mode,
      pendingScans: nextScans,
    );
    return _pairingSession!;
  }

  @override
  Future<PairingSession> disconnectPairingSession({
    required String sessionCode,
  }) async {
    final session = await getPairingSession(sessionCode);
    if (session == null) {
      throw Exception('Pairing session not found.');
    }

    _pairingSession = session.copyWith(
      status: PairingSessionStatus.waitingForPhone,
      connectedDeviceName: '',
      lastScannedQr: '',
      activeMode: null,
      pendingScans: const <PairingScanEntry>[],
    );
    return PairingSession(
      code: _pairingSession!.code,
      status: _pairingSession!.status,
      pendingScans: _pairingSession!.pendingScans,
    );
  }

  @override
  Future<void> returnItem({
    required Item item,
    required String returnerName,
    required String rackLocation,
    String? description,
  }) async {
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index == -1) return;

    final updatedItem = item.copyWith(
      currentLocation: rackLocation,
      status: ItemStatus.available,
      lastBorrowerName: returnerName,
    );

    _items[index] = updatedItem;
    _movements.insert(
      0,
      MovementRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemName: item.name,
        itemQrCode: item.qrCode,
        action: MovementAction.returnItem,
        actorName: returnerName,
        fromLocation: item.currentLocation,
        toLocation: rackLocation,
        createdAt: DateTime.now(),
        description: description,
      ),
    );
  }
}
