import 'user_role.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      role: UserRoleExtension.fromString(map['role']),
    );
  }
}
