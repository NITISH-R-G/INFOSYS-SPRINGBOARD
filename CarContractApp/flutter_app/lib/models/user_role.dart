enum UserRole { client, dealer }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.dealer:
        return 'dealer';
    }
  }

  static UserRole fromString(String role) {
    if (role == 'dealer') return UserRole.dealer;
    return UserRole.client;
  }
}
