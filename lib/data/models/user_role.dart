/// Defines the supported global roles within the Coment admin system.
enum UserRole {
  user,
  moderator,
  admin,
}

extension UserRoleParser on UserRole {
  String get label {
    switch (this) {
      case UserRole.user:
        return 'User';
      case UserRole.moderator:
        return 'Moderator';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get asValue => name;

  static UserRole fromString(String? raw) {
    switch (raw) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      default:
        return UserRole.user;
    }
  }
}

/// Tracks a user's active status across the platform.
enum UserStatus {
  active,
  muted,
  banned,
  shadowBanned,
}

extension UserStatusParser on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.active:
        return 'Active';
      case UserStatus.muted:
        return 'Muted';
      case UserStatus.banned:
        return 'Banned';
      case UserStatus.shadowBanned:
        return 'Shadow Banned';
    }
  }

  String get asValue => name;

  static UserStatus fromString(String? raw) {
    switch (raw) {
      case 'muted':
        return UserStatus.muted;
      case 'banned':
        return UserStatus.banned;
      case 'shadowBanned':
        return UserStatus.shadowBanned;
      default:
        return UserStatus.active;
    }
  }
}
