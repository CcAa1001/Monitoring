class ItemCategory {
  const ItemCategory({
    required this.id,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String name;
  final bool isActive;

  ItemCategory copyWith({
    String? id,
    String? name,
    bool? isActive,
  }) {
    return ItemCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}
