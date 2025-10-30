import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_profile.dart';

/// Forum model - Free topic forums created by users
class Forum {
  final String id;
  final String name;
  final String description;
  final String? coverImage;
  final int memberCount;
  final int messageCount;
  final DateTime? lastMessageAt;
  final String? lastMessageText;
  final String? lastMessageUser;
  final List<String> pinnedMessageIds;
  final List<String> moderatorIds;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;

  const Forum({
    required this.id,
    required this.name,
    required this.description,
    this.coverImage,
    this.memberCount = 0,
    this.messageCount = 0,
    this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageUser,
    this.pinnedMessageIds = const [],
    this.moderatorIds = const [],
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
  });

  factory Forum.fromMap(String id, Map<String, dynamic> data) {
    return Forum(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      coverImage: data['coverImage'] as String?,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      messageCount: (data['messageCount'] as num?)?.toInt() ?? 0,
      lastMessageAt: data['lastMessageAt'] != null
          ? (data['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessageText: data['lastMessageText'] as String?,
      lastMessageUser: data['lastMessageUser'] as String?,
      pinnedMessageIds: (data['pinnedMessageIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      moderatorIds: (data['moderatorIds'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      createdByName: data['createdByName'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'memberCount': memberCount,
      'messageCount': messageCount,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessageText': lastMessageText,
      'lastMessageUser': lastMessageUser,
      'pinnedMessageIds': pinnedMessageIds,
      'moderatorIds': moderatorIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByName': createdByName,
    };
  }

  /// Check if user is moderator
  bool isModerator(String userId) {
    return moderatorIds.contains(userId);
  }

  /// Check if user is the creator
  bool isCreator(String userId) {
    return createdBy == userId;
  }

  /// Check if user can delete this forum (creator, moderator, or developer)
  bool canDelete(String userId, {String? email, String? handle}) {
    // Moderators can delete (includes developer who auto-joins as moderator)
    if (moderatorIds.contains(userId)) {
      return true;
    }
    // Developer is absolute admin - can delete any forum
    if (UserProfile.isDeveloperAccount(email, handle)) {
      return true;
    }
    // Creator can delete their own forum
    return createdBy == userId;
  }

  /// Check if message is pinned
  bool isMessagePinned(String messageId) {
    return pinnedMessageIds.contains(messageId);
  }
}
