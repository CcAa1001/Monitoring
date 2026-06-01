import '../models/app_user.dart';
import '../models/item.dart';
import '../models/movement_record.dart';

class InventoryReportService {
  const InventoryReportService();

  int readyCount(List<Item> items) {
    return items.where((item) => item.status == ItemStatus.available).length;
  }

  int borrowedCount(List<Item> items) {
    return items.where((item) => item.status == ItemStatus.borrowed).length;
  }

  int overdueCount(List<Item> items) {
    return items.where((item) => item.isOverdue).length;
  }

  int dueSoonCount(List<Item> items) {
    return items.where((item) => item.isDueSoon).length;
  }

  List<MapEntry<String, int>> mostBorrowedItems(List<MovementRecord> movements, {int limit = 8}) {
    final counts = <String, int>{};
    for (final movement in movements.where((entry) => entry.action == MovementAction.borrow)) {
      counts[movement.itemName] = (counts[movement.itemName] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  List<MapEntry<String, int>> mostActiveUsers(List<MovementRecord> movements, {int limit = 8}) {
    final counts = <String, int>{};
    for (final movement in movements) {
      counts[movement.actorName] = (counts[movement.actorName] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  List<MapEntry<String, int>> locationActivity(List<MovementRecord> movements, {int limit = 8}) {
    final counts = <String, int>{};
    for (final movement in movements) {
      counts[movement.toLocation] = (counts[movement.toLocation] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  String historyCsv(List<MovementRecord> movements) {
    final rows = <String>[
      'item_name,item_qr,action,actor,from_location,to_location,time,description',
      ...movements.map((movement) {
        final action = movement.action == MovementAction.borrow ? 'Borrow' : 'Return';
        return <String>[
          movement.itemName,
          movement.itemQrCode,
          action,
          movement.actorName,
          movement.fromLocation,
          movement.toLocation,
          movement.createdAt.toIso8601String(),
          movement.description ?? '',
        ].map(_csvCell).join(',');
      }),
    ];
    return rows.join('\n');
  }

  String itemsCsv(List<Item> items) {
    final rows = <String>[
      'name,qr_code,serial_number,brand,model,category,condition,status,current_location,last_borrower,expected_return_at,notes,photo_url,manual_url',
      ...items.map((item) {
        return <String>[
          item.name,
          item.qrCode,
          item.serialNumber ?? '',
          item.brand ?? '',
          item.model ?? '',
          item.category,
          item.condition ?? '',
          item.status == ItemStatus.available ? 'Ready' : 'Borrowed',
          item.currentLocation,
          item.lastBorrowerName ?? '',
          item.expectedReturnAt?.toIso8601String() ?? '',
          item.notes ?? '',
          item.imageUrl ?? '',
          item.manualUrl ?? '',
        ].map(_csvCell).join(',');
      }),
    ];
    return rows.join('\n');
  }

  String usersCsv(List<AppUser> users) {
    final rows = <String>[
      'name,badge_id,role,is_active',
      ...users.map((user) {
        return <String>[
          user.name,
          user.badgeId,
          user.role.name,
          user.isActive ? 'active' : 'inactive',
        ].map(_csvCell).join(',');
      }),
    ];
    return rows.join('\n');
  }

  String _csvCell(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }
}
