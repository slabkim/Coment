import 'user_class.dart';

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
  });
  
  /// Get user's class based on XP
  UserClass get userClass => UserClass.fromXP(xp);

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
    };
  }
}
