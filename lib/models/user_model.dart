enum UserRole { customer, businessOwner, admin }

UserRole userRoleFromString(String value) {
  return UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.customer,
  );
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String passwordHash;
  final UserRole role;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.role,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'passwordHash': passwordHash,
        'role': role.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      passwordHash: json['passwordHash'] as String,
      role: userRoleFromString(json['role'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  AppUser copyWith({String? name, String? phone}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash,
      role: role,
      createdAt: createdAt,
    );
  }
}
