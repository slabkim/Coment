import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import 'firestore_paths.dart';

class ChatService {
  final FirebaseFirestore _db;
  ChatService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Chat>> watchUserChats(String uid) {
    return _db
        .collection(FsPaths.chats)
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Chat.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<String> ensureChat(String uidA, String uidB) async {
    final parts = [uidA, uidB]..sort();
    final key = parts.join('_');
    final doc = _db.collection(FsPaths.chats).doc(key);
    
    try {
      // Check if document already exists
      final docSnap = await doc.get();
      
      if (!docSnap.exists) {
        // Only set lastMessageTime if document is new
        await doc.set({
          'participants': parts,
          'lastMessageTime': null, // No messages yet
          'lastMessage': null,
        });
        AppLogger.debug('Chat document created: $key for participants: $parts');
      } else {
        // Document exists, just ensure participants are set (don't update timestamp)
        await doc.set({
          'participants': parts,
        }, SetOptions(merge: true));
        AppLogger.debug('Chat document ensured (already exists): $key for participants: $parts');
      }
      
      return key;
    } catch (e, stackTrace) {
      AppLogger.firebaseError('Failed to ensure chat exists for users: $uidA, $uidB', e, stackTrace);
      rethrow;
    }
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _db
        .collection(FsPaths.chatMessages)
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ChatMessage.fromMap(d.id, d.data()))
              .toList(),
        )
        .handleError((error, stackTrace) {
          AppLogger.firebaseError('watchMessages stream error for chatId: $chatId', error, stackTrace);
          // Re-throw to be caught by StreamBuilder
          throw error;
        });
  }

  Future<void> sendText({
    required String chatId,
    required String senderId,
    required String text,
    String? senderName,
  }) async {
    final batch = _db.batch();
    final msgRef = _db.collection(FsPaths.chatMessages).doc();
    batch.set(
      msgRef,
      ChatMessage(
        id: msgRef.id,
        chatId: chatId,
        senderId: senderId,
        text: text,
        imageUrl: null,
        createdAt: DateTime.now(),
      ).toMap(),
    );

    final chatRef = _db.collection(FsPaths.chats).doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'lastMessageSenderId': senderId,
      if (senderName != null) 'lastMessageSenderName': senderName,
    });

    await batch.commit();
  }

  Future<void> sendImage({
    required String chatId,
    required String senderId,
    required String imageUrl,
    String? senderName,
  }) async {
    final batch = _db.batch();
    final msgRef = _db.collection(FsPaths.chatMessages).doc();
    batch.set(
      msgRef,
      ChatMessage(
        id: msgRef.id,
        chatId: chatId,
        senderId: senderId,
        text: null,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      ).toMap(),
    );

    final chatRef = _db.collection(FsPaths.chats).doc(chatId);
    batch.update(chatRef, {
      'lastMessage': '[image]',
      'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      'lastMessageSenderId': senderId,
      if (senderName != null) 'lastMessageSenderName': senderName,
    });

    await batch.commit();
  }
}
