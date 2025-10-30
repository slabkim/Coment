import 'package:cloud_firestore/cloud_firestore.dart';

/// Forum message model
class ForumMessage {
  final String id;
  final String forumId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String text;
  final String? imageUrl;      // Phase 2
  final String? gifUrl;         // Phase 2
  final List<String> mentions;  // Phase 2
  final bool isPinned;
  final String? replyTo;        // Phase 2
  final Map<String, List<String>>? reactions;  // Phase 2: emoji -> [userIds]
  final DateTime timestamp;
  final DateTime? editedAt;

  const ForumMessage({
    required this.id,
    required this.forumId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.text,
    this.imageUrl,
    this.gifUrl,
    this.mentions = const [],
    this.isPinned = false,
    this.replyTo,
    this.reactions,
    required this.timestamp,
    this.editedAt,
  });

  factory ForumMessage.fromMap(String id, Map<String, dynamic> data) {
    return ForumMessage(
      id: id,
      forumId: data['forumId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      userAvatar: data['userAvatar'] as String?,
      text: data['text'] as String,
      imageUrl: data['imageUrl'] as String?,
      gifUrl: data['gifUrl'] as String?,
      mentions: (data['mentions'] as List<dynamic>?)?.cast<String>() ?? const [],
      isPinned: data['isPinned'] as bool? ?? false,
      replyTo: data['replyTo'] as String?,
      reactions: data['reactions'] != null
          ? (data['reactions'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, (value as List<dynamic>).cast<String>()),
            )
          : null,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      editedAt: data['editedAt'] != null
          ? (data['editedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'forumId': forumId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'text': text,
      'imageUrl': imageUrl,
      'gifUrl': gifUrl,
      'mentions': mentions,
      'isPinned': isPinned,
      'replyTo': replyTo,
      'reactions': reactions,
      'timestamp': Timestamp.fromDate(timestamp),
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }
}

