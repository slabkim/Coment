import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/forum_message.dart';

/// Service for managing forum messages
/// Service for managing forum messages (Singleton)
class ForumMessageService {
  // Singleton pattern
  static final ForumMessageService _instance = ForumMessageService._internal();
  factory ForumMessageService() => _instance;
  
  final FirebaseFirestore _db;

  ForumMessageService._internal() : _db = FirebaseFirestore.instance;

  /// Send a message to forum
  Future<String> sendMessage({
    required String forumId,
    required String userId,
    required String userName,
    String? userAvatar,
    String? text,
    String? imageUrl,
    String? gifUrl,
    String? replyTo,
    List<String>? mentions,
  }) async {
    try {
      final docRef = _db.collection('forum_messages').doc();
      
      final message = ForumMessage(
        id: docRef.id,
        forumId: forumId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        text: text ?? '',
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
        gifUrl: gifUrl,
        replyTo: replyTo,
        mentions: mentions ?? [],
        reactions: {},
      );
      
      await docRef.set(message.toMap());
      
      // Update forum's last message info
      String lastMsgText;
      if (text != null && text.isNotEmpty) {
        lastMsgText = text.length > 100 ? '${text.substring(0, 100)}...' : text;
      } else if (imageUrl != null) {
        lastMsgText = '📷 Photo';
      } else if (gifUrl != null) {
        lastMsgText = '🎬 GIF';
      } else {
        lastMsgText = 'New message';
      }
      
      await _db.collection('forums').doc(forumId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageText': lastMsgText,
        'lastMessageUser': userName,
        'messageCount': FieldValue.increment(1),
      });
      
      debugPrint('Message sent to forum $forumId: ${message.id}');
      
      return message.id;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Delete a message (moderators only)
  Future<void> deleteMessage(String messageId, String forumId) async {
    try {
      await _db.collection('forum_messages').doc(messageId).delete();
      
      // Decrement message count
      await _db.collection('forums').doc(forumId).update({
        'messageCount': FieldValue.increment(-1),
      });
      
      debugPrint('Message deleted: $messageId');
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  /// Watch messages in forum (real-time)
  Stream<List<ForumMessage>> watchMessages(String forumId, {int limit = 50}) {
    return _db
        .collection('forum_messages')
        .where('forumId', isEqualTo: forumId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ForumMessage.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Get pinned messages
  Future<List<ForumMessage>> getPinnedMessages(String forumId) async {
    try {
      final querySnapshot = await _db
          .collection('forum_messages')
          .where('forumId', isEqualTo: forumId)
          .where('isPinned', isEqualTo: true)
          .orderBy('timestamp', descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ForumMessage.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting pinned messages: $e');
      return [];
    }
  }

  /// Watch pinned messages in real-time
  Stream<List<ForumMessage>> watchPinnedMessages(String forumId) {
    return _db
        .collection('forum_messages')
        .where('forumId', isEqualTo: forumId)
        .where('isPinned', isEqualTo: true)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ForumMessage.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  /// Get message count for forum
  Future<int> getMessageCount(String forumId) async {
    try {
      final forumDoc = await _db.collection('forums').doc(forumId).get();
      if (!forumDoc.exists) return 0;
      
      final data = forumDoc.data();
      return (data?['messageCount'] as num?)?.toInt() ?? 0;
    } catch (e) {
      debugPrint('Error getting message count: $e');
      return 0;
    }
  }

  /// Add or remove a reaction to a message
  Future<void> toggleReaction(String messageId, String userId, String emoji) async {
    try {
      final messageRef = _db.collection('forum_messages').doc(messageId);
      final messageDoc = await messageRef.get();
      
      if (!messageDoc.exists) {
        throw Exception('Message not found');
      }
      
      final messageData = messageDoc.data()!;
      final reactions = Map<String, List<String>>.from(
        (messageData['reactions'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, List<String>.from(v as List)),
        ) ?? {},
      );
      
      // Toggle reaction
      if (reactions.containsKey(emoji)) {
        final users = reactions[emoji]!;
        if (users.contains(userId)) {
          users.remove(userId);
          if (users.isEmpty) {
            reactions.remove(emoji);
          }
        } else {
          users.add(userId);
        }
      } else {
        reactions[emoji] = [userId];
      }
      
      await messageRef.update({'reactions': reactions});
      
      debugPrint('Reaction toggled on message $messageId: $emoji by $userId');
    } catch (e) {
      debugPrint('Error toggling reaction: $e');
      rethrow;
    }
  }
}

