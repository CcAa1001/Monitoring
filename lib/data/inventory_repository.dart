import '../models/allowed_location.dart';
import '../models/app_user.dart';
import '../config/app_config.dart';
import '../models/item.dart';
import '../models/item_category.dart';
import '../models/movement_record.dart';
import '../models/pairing_session.dart';
import 'mock_inventory_repository.dart';
import 'supabase_inventory_repository.dart';

abstract class InventoryRepository {
  Future<List<Item>> getItems();
  Future<void> addItem(Item item);
  Future<void> updateItem(Item item);
  Future<void> deleteItem(String itemId);

  Future<List<ItemCategory>> getCategories();
  Future<void> addCategory(ItemCategory category);
  Future<void> updateCategory(ItemCategory category);
  Future<void> deleteCategory(String categoryId);

  Future<List<MovementRecord>> getRecentMovements();

  Future<Item?> findItemByQr(String qrCode);

  Future<List<AllowedLocation>> getAllowedLocations();
  Future<void> addLocation(AllowedLocation location);
  Future<void> updateLocation(AllowedLocation location);
  Future<void> deleteLocation(String locationId);

  Future<List<AppUser>> getUsers();
  Future<void> addUser(AppUser user);
  Future<void> updateUser(AppUser user);
  Future<void> deleteUser(String userId);
  Future<AppUser?> authenticate({
    required String badgeId,
    required String password,
  });

  Future<void> borrowItem({
    required Item item,
    required String borrowerName,
    required String destinationLine,
    String? description,
  });

  Future<void> returnItem({
    required Item item,
    required String returnerName,
    required String rackLocation,
    String? description,
  });

  Future<PairingSession> createPairingSession();

  Future<PairingSession> connectPhoneToSession({
    required String sessionCode,
    required String deviceName,
  });

  Future<PairingSession> setPairingMode({
    required String sessionCode,
    required PairActionMode mode,
  });

  Future<PairingSession?> getPairingSession(String sessionCode);

  Future<PairingSession> submitPhoneScan({
    required String sessionCode,
    required String qrCode,
    required PairActionMode mode,
  });

  Future<PairingSession> consumePairingScan({
    required String sessionCode,
    required String qrCode,
  });

  Future<PairingSession> disconnectPairingSession({
    required String sessionCode,
  });
}

class InventoryRepositoryFactory {
  static Future<InventoryRepository> create() async {
    if (AppConfig.useSupabase) {
      return SupabaseInventoryRepository.initialize();
    }

    return MockInventoryRepository.seeded();
  }
}
