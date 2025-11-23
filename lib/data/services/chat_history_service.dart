import 'dart:async';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';
import 'firestore_paths.dart';

class ChatHistoryService {
  final FirebaseFirestore _db;
  ChatHistoryService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  // chat_history document id suggestion: "{chatId}_{userId}"
  String _docId(String chatId, String userId) => '${chatId}_$userId';

  Stream<int?> watchLastRead(String chatId, String userId) async* {
    await for (final snap
        in _db.collection(FsPaths.chats).doc(chatId).snapshots()) {
      try {
        final map = snap.data()?['lastRead'];
        if (map is Map<String, dynamic>) {
          final raw = map[userId];
          if (raw is num) {
            yield raw.toInt();
            continue;
          }
        }
      } catch (error, stackTrace) {
        AppLogger.firebaseError(
          'Parsing lastRead map for chatId: $chatId',
          error,
          stackTrace,
        );
      }
      // Fallback to legacy chat_history doc if map missing
      final legacy = await _db
          .collection('chat_history')
          .doc(_docId(chatId, userId))
          .get();
      final value = legacy.data()?['lastReadAt'];
      if (value is num) {
        yield value.toInt();
      } else {
        yield null;
      }
    }
  }

  Future<void> markReadNow(String chatId, String userId) async {
    final id = _docId(chatId, userId);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final futures = <Future<void>>[];

    futures.add(_db.collection('chat_history').doc(id).set({
      'chatId': chatId,
      'userId': userId,
      'lastReadAt': timestamp,
    }, SetOptions(merge: true)));

    futures.add(_db.collection(FsPaths.chats).doc(chatId).set({
      'lastRead': {userId: timestamp},
    }, SetOptions(merge: true)));

    try {
      await Future.wait(futures);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
    }
  }
}
