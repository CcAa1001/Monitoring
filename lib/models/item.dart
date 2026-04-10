enum ItemStatus {
  available,
  borrowed,
}

class Item {
  const Item({
    required this.id,
    required this.qrCode,
    required this.name,
    required this.category,
    required this.currentLocation,
    required this.status,
    this.lastBorrowerName,
  });

  final String id;
  final String qrCode;
  final String name;
  final String category;
  final String currentLocation;
  final ItemStatus status;
  final String? lastBorrowerName;

  Item copyWith({
    String? id,
    String? qrCode,
    String? name,
    String? category,
    String? currentLocation,
    ItemStatus? status,
    String? lastBorrowerName,
  }) {
    return Item(
      id: id ?? this.id,
      qrCode: qrCode ?? this.qrCode,
      name: name ?? this.name,
      category: category ?? this.category,
      currentLocation: currentLocation ?? this.currentLocation,
      status: status ?? this.status,
      lastBorrowerName: lastBorrowerName ?? this.lastBorrowerName,
    );
  }
}
