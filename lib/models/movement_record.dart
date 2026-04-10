enum MovementAction {
  borrow,
  returnItem,
}

class MovementRecord {
  const MovementRecord({
    required this.id,
    required this.itemName,
    required this.itemQrCode,
    required this.action,
    required this.actorName,
    required this.fromLocation,
    required this.toLocation,
    required this.createdAt,
    this.description,
  });

  final String id;
  final String itemName;
  final String itemQrCode;
  final MovementAction action;
  final String actorName;
  final String fromLocation;
  final String toLocation;
  final DateTime createdAt;
  final String? description;
}
