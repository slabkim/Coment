class UserProfile {
  final String id;
  final String? username;
  final String? email;
  final String? handle;
  final String? bio;
  final String? photoUrl;
  final DateTime? joinedAt;
  final DateTime? lastSeen;

  const UserProfile({
    required this.id,
    this.username,
    this.email,
    this.handle,
    this.bio,
    this.photoUrl,
    this.joinedAt,
    this.lastSeen,
  });

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
    
    return UserProfile(
      id: id,
      username: data['username'] as String?,
      email: data['email'] as String?,
      handle: data['handle'] as String?,
      bio: data['bio'] as String?,
      photoUrl: data['photoUrl'] as String?,
      joinedAt: joinedAt,
      lastSeen: lastSeen,
    );
  }
}
