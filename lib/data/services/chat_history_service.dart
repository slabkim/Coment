import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';

class ChatHistoryService {
  final FirebaseFirestore _db;
  ChatHistoryService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  // chat_history document id suggestion: "{chatId}_{userId}"
  String _docId(String chatId, String userId) => '${chatId}_$userId';

  Stream<int?> watchLastRead(String chatId, String userId) {
    final id = _docId(chatId, userId);
    return _db.collection('chat_history').doc(id).snapshots().map((d) {
      if (!d.exists) return null;
      final v = d.data()?['lastReadAt'];
      return (v is num) ? v.toInt() : null;
    }).handleError((error, stackTrace) {
      AppLogger.firebaseError('watchLastRead failed for chatId: $chatId, userId: $userId', error, stackTrace);
      // Don't rethrow - stream will emit null if document doesn't exist
      // This allows the UI to continue working even if permission is denied
    });
  }

  Future<void> markReadNow(String chatId, String userId) async {
    final id = _docId(chatId, userId);
    try {
      await _db.collection('chat_history').doc(id).set({
        'chatId': chatId,
        'userId': userId,
        'lastReadAt': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      // Swallow permission-denied errors; user might not have rights
      // (e.g., signed out or rules mismatch). Avoid crashing/UI noise.
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }
  }
}
