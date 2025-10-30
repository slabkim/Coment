import 'package:cloud_firestore/cloud_firestore.dart';

/// Forum member role
enum ForumMemberRole {
  member,
  moderator,
}

/// Forum member model
class ForumMember {
  final String forumId;
  final String userId;
  final ForumMemberRole role;
  final DateTime joinedAt;
  final DateTime? lastReadAt;
  final bool muted;

  const ForumMember({
    required this.forumId,
    required this.userId,
    this.role = ForumMemberRole.member,
    required this.joinedAt,
    this.lastReadAt,
    this.muted = false,
  });

  factory ForumMember.fromMap(Map<String, dynamic> data) {
    return ForumMember(
      forumId: data['forumId'] as String,
      userId: data['userId'] as String,
      role: data['role'] == 'moderator' 
          ? ForumMemberRole.moderator 
          : ForumMemberRole.member,
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      lastReadAt: data['lastReadAt'] != null
          ? (data['lastReadAt'] as Timestamp).toDate()
          : null,
      muted: data['muted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'forumId': forumId,
      'userId': userId,
      'role': role == ForumMemberRole.moderator ? 'moderator' : 'member',
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastReadAt': lastReadAt != null ? Timestamp.fromDate(lastReadAt!) : null,
      'muted': muted,
    };
  }

  /// Check if member is moderator
  bool get isModerator => role == ForumMemberRole.moderator;
}

/// User forum subscription (for "my forums" list)
class UserForumSubscription {
  final String userId;
  final String forumId;
  final int unreadCount;
  final DateTime? lastReadAt;

  const UserForumSubscription({
    required this.userId,
    required this.forumId,
    this.unreadCount = 0,
    this.lastReadAt,
  });

  factory UserForumSubscription.fromMap(Map<String, dynamic> data) {
    return UserForumSubscription(
      userId: data['userId'] as String,
      forumId: data['forumId'] as String,
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      lastReadAt: data['lastReadAt'] != null
          ? (data['lastReadAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'forumId': forumId,
      'unreadCount': unreadCount,
      'lastReadAt': lastReadAt != null ? Timestamp.fromDate(lastReadAt!) : null,
    };
  }
}

