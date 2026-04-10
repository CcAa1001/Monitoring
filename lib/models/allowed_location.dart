enum LocationType {
  line,
  rack,
}

class AllowedLocation {
  const AllowedLocation({
    required this.id,
    required this.code,
    required this.type,
    required this.isActive,
  });

  final String id;
  final String code;
  final LocationType type;
  final bool isActive;

  AllowedLocation copyWith({
    String? id,
    String? code,
    LocationType? type,
    bool? isActive,
  }) {
    return AllowedLocation(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }
}
