import 'package:cloud_firestore/cloud_firestore.dart';
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
        .map((snap) => snap.docs
            .map((d) => Chat.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String> ensureChat(String uidA, String uidB) async {
    final parts = [uidA, uidB]..sort();
    final key = parts.join('_');
    final doc = _db.collection(FsPaths.chats).doc(key);
    final exists = await doc.get();
    if (!exists.exists) {
      await doc.set({
        'participants': parts,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });
    }
    return key;
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _db
        .collection(FsPaths.chatMessages)
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatMessage.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> sendText({
    required String chatId,
    required String senderId,
    required String text,
    String? senderName,
  }) async {
    final batch = _db.batch();
    final msgRef = _db.collection(FsPaths.chatMessages).doc();
    batch.set(msgRef, ChatMessage(
      id: msgRef.id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      imageUrl: null,
      createdAt: DateTime.now(),
    ).toMap());

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
    batch.set(msgRef, ChatMessage(
      id: msgRef.id,
      chatId: chatId,
      senderId: senderId,
      text: null,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    ).toMap());

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


