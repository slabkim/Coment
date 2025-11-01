import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';
import '../models/user_profile.dart';
import 'package:rxdart/rxdart.dart' as rx;

class UserService {
  final FirebaseFirestore _db;
  UserService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  Future<void> ensureUserDoc({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'email': email,
        'username': displayName ?? email.split('@').first,
        'handle': email.split('@').first,
        'usernameLower': (displayName ?? email.split('@').first).toLowerCase(),
        'handleLower': email.split('@').first.toLowerCase(),
        'photoUrl': photoUrl ?? '',
        'bio': '',
        'joinAt': DateTime.now().millisecondsSinceEpoch,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
  
  /// Update user's last seen timestamp
  Future<void> updateLastSeen(String uid) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _db.collection('users').doc(uid).set({
        'lastSeen': timestamp,
      }, SetOptions(merge: true));
    } catch (e, stackTrace) {
      // Log warning instead of silently failing
      // This is a non-critical operation, but we should track failures
      AppLogger.warning('Failed to update lastSeen for user: $uid', e, stackTrace);
    }
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.id, doc.data()!);
    });
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.id, doc.data()!);
  }

  /// Basic user search by handle or username prefix (case-insensitive)
  Stream<List<UserProfile>> searchUsers(String query, {int limit = 20}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const Stream<List<UserProfile>>.empty();
    // Assuming we store lowercase handle/username fields for indexing
    final handleQ = _db
        .collection('users')
        .where('handleLower', isGreaterThanOrEqualTo: q)
        .where('handleLower', isLessThan: '${q}~')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => UserProfile.fromMap(d.id, d.data())).toList());
    final usernameQ = _db
        .collection('users')
        .where('usernameLower', isGreaterThanOrEqualTo: q)
        .where('usernameLower', isLessThan: '${q}~')
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => UserProfile.fromMap(d.id, d.data())).toList());
    return rx.CombineLatestStream.list<List<UserProfile>>([handleQ, usernameQ])
        .map((lists) {
      final a = lists.isNotEmpty ? lists[0] : const <UserProfile>[];
      final b = lists.length > 1 ? lists[1] : const <UserProfile>[];
      final map = <String, UserProfile>{};
      for (final u in [...a, ...b]) {
        map[u.id] = u;
      }
      return map.values.toList();
    });
  }
}
