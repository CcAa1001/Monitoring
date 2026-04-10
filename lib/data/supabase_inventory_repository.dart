import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/allowed_location.dart';
import '../models/app_user.dart';
import '../config/app_config.dart';
import '../models/item.dart';
import '../models/item_category.dart';
import '../models/movement_record.dart';
import '../models/pairing_session.dart';
import 'inventory_repository.dart';

class SupabaseInventoryRepository implements InventoryRepository {
  SupabaseInventoryRepository._(this._client);

  final SupabaseClient _client;

  static Future<SupabaseInventoryRepository> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );

    return SupabaseInventoryRepository._(Supabase.instance.client);
  }

  UserRole _mapUserRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'operator':
        return UserRole.operator;
      case 'viewer':
      default:
        return UserRole.viewer;
    }
  }

  @override
  Future<void> addItem(Item item) async {
    await _client.from('items').insert(<String, dynamic>{
      'qr_code': item.qrCode,
      'name': item.name,
      'category': item.category,
      'current_status': item.status == ItemStatus.borrowed ? 'borrowed' : 'available',
      'current_location': item.currentLocation,
      'last_borrower_name': item.lastBorrowerName,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateItem(Item item) async {
    await _client.from('items').update(<String, dynamic>{
      'qr_code': item.qrCode,
      'name': item.name,
      'category': item.category,
      'current_status': item.status == ItemStatus.borrowed ? 'borrowed' : 'available',
      'current_location': item.currentLocation,
      'last_borrower_name': item.lastBorrowerName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', item.id);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    await _client.from('items').delete().eq('id', itemId);
  }

  @override
  Future<void> borrowItem({
    required Item item,
    required String borrowerName,
    required String destinationLine,
    String? description,
  }) async {
    await _client.from('items').update(<String, dynamic>{
      'current_status': 'borrowed',
      'current_location': destinationLine,
      'last_borrower_name': borrowerName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', item.id);

    await _client.from('movements').insert(<String, dynamic>{
      'item_id': item.id,
      'action_type': 'borrow',
      'actor_name': borrowerName,
      'from_location': item.currentLocation,
      'to_location': destinationLine,
      'description': description,
    });
  }

  @override
  Future<Item?> findItemByQr(String qrCode) async {
    final response = await _client
        .from('items')
        .select()
        .eq('qr_code', qrCode)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return _mapItem(response);
  }

  @override
  Future<List<Item>> getItems() async {
    final response = await _client
        .from('items')
        .select()
        .order('updated_at', ascending: false);

    return response.map<Item>(_mapItem).toList();
  }

  @override
  Future<List<AllowedLocation>> getAllowedLocations() async {
    final response = await _client
        .from('allowed_locations')
        .select()
        .order('code');

    return response.map<AllowedLocation>((dynamic row) {
      final map = row as Map<String, dynamic>;
      return AllowedLocation(
        id: map['id'].toString(),
        code: map['code'] as String,
        type: (map['location_type'] as String? ?? 'rack') == 'line'
            ? LocationType.line
            : LocationType.rack,
        isActive: map['is_active'] as bool? ?? true,
      );
    }).toList();
  }

  @override
  Future<List<ItemCategory>> getCategories() async {
    try {
      final response = await _client
          .from('item_categories')
          .select()
          .order('name');

      return response.map<ItemCategory>((dynamic row) {
        final map = row as Map<String, dynamic>;
        return ItemCategory(
          id: map['id'].toString(),
          name: map['name'] as String,
          isActive: map['is_active'] as bool? ?? true,
        );
      }).toList();
    } catch (_) {
      return <ItemCategory>[];
    }
  }

  @override
  Future<void> addCategory(ItemCategory category) async {
    await _client.from('item_categories').insert(<String, dynamic>{
      'name': category.name,
      'is_active': category.isActive,
    });
  }

  @override
  Future<void> updateCategory(ItemCategory category) async {
    await _client.from('item_categories').update(<String, dynamic>{
      'name': category.name,
      'is_active': category.isActive,
    }).eq('id', category.id);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _client.from('item_categories').delete().eq('id', categoryId);
  }

  @override
  Future<void> addLocation(AllowedLocation location) async {
    await _client.from('allowed_locations').insert(<String, dynamic>{
      'code': location.code,
      'location_type': location.type == LocationType.line ? 'line' : 'rack',
      'is_active': location.isActive,
    });
  }

  @override
  Future<void> updateLocation(AllowedLocation location) async {
    await _client.from('allowed_locations').update(<String, dynamic>{
      'code': location.code,
      'location_type': location.type == LocationType.line ? 'line' : 'rack',
      'is_active': location.isActive,
    }).eq('id', location.id);
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    await _client.from('allowed_locations').delete().eq('id', locationId);
  }

  @override
  Future<List<MovementRecord>> getRecentMovements() async {
    final response = await _client
        .from('movements')
        .select(
          'id, action_type, actor_name, from_location, to_location, created_at, description, items(name, qr_code)',
        )
        .order('created_at', ascending: false)
        .limit(20);

    return response.map<MovementRecord>((dynamic row) {
      final map = row as Map<String, dynamic>;
      final itemMap = (map['items'] as Map<String, dynamic>? ?? <String, dynamic>{});
      final actionType = map['action_type'] as String? ?? 'borrow';

      return MovementRecord(
        id: map['id'].toString(),
        itemName: itemMap['name'] as String? ?? 'Unknown item',
        itemQrCode: itemMap['qr_code'] as String? ?? '-',
        action: actionType == 'return' ? MovementAction.returnItem : MovementAction.borrow,
        actorName: map['actor_name'] as String? ?? '-',
        fromLocation: map['from_location'] as String? ?? '-',
        toLocation: map['to_location'] as String? ?? '-',
        createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
        description: map['description'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<AppUser>> getUsers() async {
    final response = await _client
        .from('app_users')
        .select()
        .order('name');

    return response.map<AppUser>((dynamic row) {
      final map = row as Map<String, dynamic>;
      return AppUser(
        id: map['id'].toString(),
        name: map['name'] as String,
        badgeId: map['badge_id'] as String,
        password: map['password'] as String,
        role: _mapUserRole(map['role'] as String?),
        isActive: map['is_active'] as bool? ?? true,
      );
    }).toList();
  }

  @override
  Future<AppUser?> authenticate({
    required String badgeId,
    required String password,
  }) async {
    final response = await _client
        .from('app_users')
        .select()
        .eq('badge_id', badgeId)
        .eq('password', password)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return AppUser(
      id: response['id'].toString(),
      name: response['name'] as String,
      badgeId: response['badge_id'] as String,
      password: response['password'] as String,
      role: _mapUserRole(response['role'] as String?),
      isActive: response['is_active'] as bool? ?? true,
    );
  }

  @override
  Future<void> addUser(AppUser user) async {
    await _client.from('app_users').insert(<String, dynamic>{
      'name': user.name,
      'badge_id': user.badgeId,
      'password': user.password,
      'role': user.role.name,
      'is_active': user.isActive,
    });
  }

  @override
  Future<void> updateUser(AppUser user) async {
    await _client.from('app_users').update(<String, dynamic>{
      'name': user.name,
      'badge_id': user.badgeId,
      'password': user.password,
      'role': user.role.name,
      'is_active': user.isActive,
    }).eq('id', user.id);
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _client.from('app_users').delete().eq('id', userId);
  }

  @override
  Future<PairingSession> createPairingSession() async {
    final response = await _client.from('pairing_sessions').insert(<String, dynamic>{
      'status': 'waiting',
    }).select().single();

    return PairingSession(
      code: response['code'] as String? ?? 'UNKNOWN',
      status: PairingSessionStatus.waitingForPhone,
    );
  }

  @override
  Future<PairingSession?> getPairingSession(String sessionCode) async {
    final response = await _client
        .from('pairing_sessions')
        .select()
        .eq('code', sessionCode)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    final lastScannedQr = response['last_scanned_qr'] as String?;
    final activeMode = _mapActionMode(response['active_mode'] as String?);
    return PairingSession(
      code: response['code'] as String? ?? sessionCode,
      status: _mapSessionStatus(response['status'] as String?),
      connectedDeviceName: response['connected_device_name'] as String?,
      lastScannedQr: lastScannedQr,
      activeMode: activeMode,
      pendingScans: lastScannedQr == null || activeMode == null
          ? const <PairingScanEntry>[]
          : <PairingScanEntry>[
              PairingScanEntry(
                qrCode: lastScannedQr,
                mode: activeMode,
                scannedAt: DateTime.now(),
                scannedBy: response['connected_device_name'] as String?,
              ),
            ],
    );
  }

  @override
  Future<PairingSession> setPairingMode({
    required String sessionCode,
    required PairActionMode mode,
  }) async {
    final response = await _client
        .from('pairing_sessions')
        .update(<String, dynamic>{
          'status': 'connected',
          'active_mode': _serializePairActionMode(mode),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('code', sessionCode)
        .select()
        .single();

    return PairingSession(
      code: response['code'] as String? ?? sessionCode,
      status: _mapSessionStatus(response['status'] as String?),
      connectedDeviceName: response['connected_device_name'] as String?,
      lastScannedQr: response['last_scanned_qr'] as String?,
      activeMode: _mapActionMode(response['active_mode'] as String?),
      pendingScans: const <PairingScanEntry>[],
    );
  }

  @override
  Future<PairingSession> connectPhoneToSession({
    required String sessionCode,
    required String deviceName,
  }) async {
    final response = await _client
        .from('pairing_sessions')
        .update(<String, dynamic>{
          'status': 'connected',
          'connected_device_name': deviceName,
        })
        .eq('code', sessionCode)
        .select()
        .single();

    return PairingSession(
      code: response['code'] as String? ?? sessionCode,
      status: PairingSessionStatus.connected,
      connectedDeviceName: response['connected_device_name'] as String?,
      lastScannedQr: response['last_scanned_qr'] as String?,
      activeMode: _mapActionMode(response['active_mode'] as String?),
    );
  }

  @override
  Future<void> returnItem({
    required Item item,
    required String returnerName,
    required String rackLocation,
    String? description,
  }) async {
    await _client.from('items').update(<String, dynamic>{
      'current_status': 'available',
      'current_location': rackLocation,
      'last_borrower_name': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', item.id);

    await _client.from('movements').insert(<String, dynamic>{
      'item_id': item.id,
      'action_type': 'return',
      'actor_name': returnerName,
      'from_location': item.currentLocation,
      'to_location': rackLocation,
      'description': description,
    });
  }

  @override
  Future<PairingSession> submitPhoneScan({
    required String sessionCode,
    required String qrCode,
    required PairActionMode mode,
  }) async {
    final response = await _client
        .from('pairing_sessions')
        .update(<String, dynamic>{
          'status': 'scanned',
          'last_scanned_qr': qrCode,
          'active_mode': _serializePairActionMode(mode),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('code', sessionCode)
        .select()
        .single();

    return PairingSession(
      code: response['code'] as String? ?? sessionCode,
      status: _mapSessionStatus(response['status'] as String?),
      connectedDeviceName: response['connected_device_name'] as String?,
      lastScannedQr: response['last_scanned_qr'] as String?,
      activeMode: _mapActionMode(response['active_mode'] as String?),
    );
  }

  @override
  Future<PairingSession> consumePairingScan({
    required String sessionCode,
    required String qrCode,
  }) async {
    final response = await _client
        .from('pairing_sessions')
        .update(<String, dynamic>{
          'status': 'connected',
          'last_scanned_qr': null,
          'active_mode': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('code', sessionCode)
        .select()
        .single();

    return PairingSession(
      code: response['code'] as String? ?? sessionCode,
      status: _mapSessionStatus(response['status'] as String?),
      connectedDeviceName: response['connected_device_name'] as String?,
      lastScannedQr: response['last_scanned_qr'] as String?,
      activeMode: _mapActionMode(response['active_mode'] as String?),
    );
  }

  @override
  Future<PairingSession> disconnectPairingSession({
    required String sessionCode,
  }) async {
    final response = await _client
        .from('pairing_sessions')
        .update(<String, dynamic>{
          'status': 'waiting',
          'connected_device_name': null,
          'last_scanned_qr': null,
          'active_mode': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('code', sessionCode)
        .select()
        .single();

    return PairingSession(
      code: response['code'] as String? ?? sessionCode,
      status: _mapSessionStatus(response['status'] as String?),
      pendingScans: const <PairingScanEntry>[],
    );
  }

  Item _mapItem(Map<String, dynamic> map) {
    return Item(
      id: map['id'].toString(),
      qrCode: map['qr_code'] as String? ?? '-',
      name: map['name'] as String? ?? 'Unknown item',
      category: map['category'] as String? ?? 'Uncategorized',
      currentLocation: map['current_location'] as String? ?? '-',
      status: (map['current_status'] as String? ?? 'available') == 'borrowed'
          ? ItemStatus.borrowed
          : ItemStatus.available,
      lastBorrowerName: map['last_borrower_name'] as String?,
    );
  }

  PairingSessionStatus _mapSessionStatus(String? status) {
    switch (status) {
      case 'scanned':
        return PairingSessionStatus.scanned;
      case 'connected':
        return PairingSessionStatus.connected;
      case 'waiting':
        return PairingSessionStatus.waitingForPhone;
      default:
        return PairingSessionStatus.idle;
    }
  }

  PairActionMode? _mapActionMode(String? mode) {
    switch (mode) {
      case 'borrow':
        return PairActionMode.borrow;
      case 'return':
        return PairActionMode.returnItem;
      case 'register':
        return PairActionMode.registerItem;
      default:
        return null;
    }
  }

  String _serializePairActionMode(PairActionMode mode) {
    switch (mode) {
      case PairActionMode.borrow:
        return 'borrow';
      case PairActionMode.returnItem:
        return 'return';
      case PairActionMode.registerItem:
        return 'register';
    }
  }
}
