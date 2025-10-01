class UserProfile {
  final String id;
  final String? username;
  final String? email;
  final String? handle;
  final String? bio;
  final String? photoUrl;
  final DateTime? joinedAt;

  const UserProfile({
    required this.id,
    this.username,
    this.email,
    this.handle,
    this.bio,
    this.photoUrl,
    this.joinedAt,
  });

  factory UserProfile.fromMap(String id, Map<String, dynamic> data) {
    final joined = data['joinAt'] ?? data['joinedAt'];
    DateTime? joinedAt;
    if (joined is num) {
      joinedAt = DateTime.fromMillisecondsSinceEpoch(joined.toInt());
    }
    return UserProfile(
      id: id,
      username: data['username'] as String?,
      email: data['email'] as String?,
      handle: data['handle'] as String?,
      bio: data['bio'] as String?,
      photoUrl: data['photoUrl'] as String?,
      joinedAt: joinedAt,
    );
  }
}
