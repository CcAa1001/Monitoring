enum UserRole {
  admin,
  operator,
  viewer,
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.badgeId,
    required this.password,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String name;
  final String badgeId;
  final String password;
  final UserRole role;
  final bool isActive;

  AppUser copyWith({
    String? id,
    String? name,
    String? badgeId,
    String? password,
    UserRole? role,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      badgeId: badgeId ?? this.badgeId,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
