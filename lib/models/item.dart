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
    this.serialNumber,
    this.brand,
    this.model,
    this.condition,
    this.imageUrl,
    this.manualUrl,
    this.notes,
    this.expectedReturnAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String qrCode;
  final String name;
  final String category;
  final String currentLocation;
  final ItemStatus status;
  final String? lastBorrowerName;
  final String? serialNumber;
  final String? brand;
  final String? model;
  final String? condition;
  final String? imageUrl;
  final String? manualUrl;
  final String? notes;
  final DateTime? expectedReturnAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOverdue {
    final dueAt = expectedReturnAt;
    if (status != ItemStatus.borrowed || dueAt == null) return false;
    return dueAt.isBefore(DateTime.now());
  }

  bool get isDueSoon {
    final dueAt = expectedReturnAt;
    if (status != ItemStatus.borrowed || dueAt == null || isOverdue) return false;
    return dueAt.difference(DateTime.now()).inHours <= 24;
  }

  String get conditionLabel {
    final value = condition?.trim();
    return value == null || value.isEmpty ? 'Unspecified' : value;
  }

  Item copyWith({
    String? id,
    String? qrCode,
    String? name,
    String? category,
    String? currentLocation,
    ItemStatus? status,
    String? lastBorrowerName,
    String? serialNumber,
    String? brand,
    String? model,
    String? condition,
    String? imageUrl,
    String? manualUrl,
    String? notes,
    DateTime? expectedReturnAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearLastBorrowerName = false,
    bool clearExpectedReturnAt = false,
  }) {
    return Item(
      id: id ?? this.id,
      qrCode: qrCode ?? this.qrCode,
      name: name ?? this.name,
      category: category ?? this.category,
      currentLocation: currentLocation ?? this.currentLocation,
      status: status ?? this.status,
      lastBorrowerName: clearLastBorrowerName ? null : lastBorrowerName ?? this.lastBorrowerName,
      serialNumber: serialNumber ?? this.serialNumber,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      manualUrl: manualUrl ?? this.manualUrl,
      notes: notes ?? this.notes,
      expectedReturnAt: clearExpectedReturnAt ? null : expectedReturnAt ?? this.expectedReturnAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
