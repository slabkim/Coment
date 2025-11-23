import 'user_class.dart';
import 'user_role.dart';

class UserProfile {
  final String id;
  final String? username;
  final String? email;
  final String? handle;
  final String? bio;
  final String? photoUrl;
  final String? coverPhotoUrl;
  final DateTime? joinedAt;
  final DateTime? lastSeen;
  final int xp; // Total XP earned
  final List<String> favoriteMangaIds;
  final String? customStatus;
  final String? profileThemeColor;
  final Map<String, dynamic>? stats;
  final bool isDeveloper;
  final UserRole role;
  final UserStatus status;
  final DateTime? mutedUntil;
  final DateTime? bannedUntil;
  final bool shadowBanned;
  final String? lastSanctionReason;
  final int sanctionCount;
  final Map<String, dynamic>? moderationFlags;

  const UserProfile({
    required this.id,
    this.username,
    this.email,
    this.handle,
    this.bio,
    this.photoUrl,
    this.coverPhotoUrl,
    this.joinedAt,
    this.lastSeen,
    this.xp = 0,
    this.favoriteMangaIds = const [],
    this.customStatus,
    this.profileThemeColor,
    this.stats,
    this.isDeveloper = false,
    this.role = UserRole.user,
    this.status = UserStatus.active,
    this.mutedUntil,
    this.bannedUntil,
    this.shadowBanned = false,
    this.lastSanctionReason,
    this.sanctionCount = 0,
    this.moderationFlags,
  });
  
  /// Get user's class based on XP
  UserClass get userClass => UserClass.fromXP(xp);

  bool get isMuted {
    if (status != UserStatus.muted) return false;
    if (mutedUntil == null) return true;
    return mutedUntil!.isAfter(DateTime.now());
  }

  bool get isBanned {
    if (status != UserStatus.banned) return false;
    if (bannedUntil == null) return true;
    return bannedUntil!.isAfter(DateTime.now());
  }

  bool get canModerate => role == UserRole.moderator || role == UserRole.admin;

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    final joined = data['joinAt'] ?? data['joinedAt'];
    DateTime? joinedAt;
    if (joined is num) {
      joinedAt = DateTime.fromMillisecondsSinceEpoch(joined.toInt());
    }
    
    final lastSeenData = data['lastSeen'];
    DateTime? lastSeen;
    if (lastSeenData is num) {
      lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenData.toInt());
    }
    DateTime? parseDate(dynamic raw) {
      if (raw is num) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
      }
      return null;
    }
    
    // Auto-detect developer based on email or handle
    final email = data['email'] as String?;
    final handle = data['handle'] as String?;
    final isDev = isDeveloperAccount(email, handle);
    
    return UserProfile(
      id: id,
      username: data['username'] as String?,
      email: email,
      handle: handle,
      bio: data['bio'] as String?,
      photoUrl: data['photoUrl'] as String?,
      coverPhotoUrl: data['coverPhotoUrl'] as String?,
      joinedAt: joinedAt,
      lastSeen: lastSeen,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      favoriteMangaIds: (data['favoriteMangaIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      customStatus: data['customStatus'] as String?,
      profileThemeColor: data['profileThemeColor'] as String?,
      stats: data['stats'] as Map<String, dynamic>?,
      isDeveloper: isDev,
      role: UserRoleParser.fromString(data['role'] as String?),
      status: UserStatusParser.fromString(data['status'] as String?),
      mutedUntil: parseDate(data['mutedUntil']),
      bannedUntil: parseDate(data['bannedUntil']),
      shadowBanned: data['shadowBanned'] as bool? ?? false,
      lastSanctionReason: data['lastSanctionReason'] as String?,
      sanctionCount: (data['sanctionCount'] as num?)?.toInt() ?? 0,
      moderationFlags: data['moderationFlags'] as Map<String, dynamic>?,
    );
  }
  
  static bool isDeveloperAccount(String? email, String? handle) {
    const devEmails = [
      'anandasubing190305@gmail.com',
    ];
    const devHandles = [
      'anandaanhar',
      '@anandaanhar',
    ];
    
    if (email != null && devEmails.contains(email.toLowerCase())) {
      return true;
    }
    if (handle != null && devHandles.contains(handle.toLowerCase())) {
      return true;
    }
    return false;
  }
  
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'handle': handle,
      'bio': bio,
      'photoUrl': photoUrl,
      'coverPhotoUrl': coverPhotoUrl,
      'joinedAt': joinedAt?.millisecondsSinceEpoch,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'xp': xp,
      'favoriteMangaIds': favoriteMangaIds,
      'customStatus': customStatus,
      'profileThemeColor': profileThemeColor,
      'stats': stats,
      'role': role.asValue,
      'status': status.asValue,
      'shadowBanned': shadowBanned,
      'sanctionCount': sanctionCount,
      if (mutedUntil != null) 'mutedUntil': mutedUntil!.millisecondsSinceEpoch,
      if (bannedUntil != null) 'bannedUntil': bannedUntil!.millisecondsSinceEpoch,
      if (lastSanctionReason != null) 'lastSanctionReason': lastSanctionReason,
      if (moderationFlags != null) 'moderationFlags': moderationFlags,
    };
  }
}
