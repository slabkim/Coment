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
    final existing = snap.data() ?? <String, dynamic>{};
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final normalizedEmail = email.trim();
    final emailLocalPart = normalizedEmail.split('@').first;

    String? sanitize(dynamic value) {
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final fallbackUsername = sanitize(displayName) ?? emailLocalPart;
    final resolvedUsername =
        sanitize(existing['username']) ?? fallbackUsername;
    final resolvedHandle =
        sanitize(existing['handle']) ?? emailLocalPart;

    final updates = <String, dynamic>{};

    void ensureValue(String key, dynamic value) {
      final current = existing[key];
      final missing = current == null ||
          (current is String && current.trim().isEmpty) ||
          (current is num && current == 0 && value is! num);
      if (missing) {
        updates[key] = value;
      }
    }

    ensureValue('email', normalizedEmail);
    ensureValue('username', resolvedUsername);
    ensureValue('handle', resolvedHandle);
    ensureValue('usernameLower', resolvedUsername.toLowerCase());
    ensureValue('handleLower', resolvedHandle.toLowerCase());
    ensureValue('photoUrl', photoUrl ?? '');
    ensureValue('joinAt', nowMs);
    ensureValue('lastSeen', nowMs);
    ensureValue('role', 'user');
    ensureValue('status', 'active');
    ensureValue('shadowBanned', false);
    ensureValue('sanctionCount', 0);

    final keywords = existing['searchKeywords'];
    final needsKeywords = keywords == null ||
        (keywords is Iterable && keywords.isEmpty);
    if (needsKeywords) {
      updates['searchKeywords'] = _buildSearchKeywords(
        username: resolvedUsername,
        handle: resolvedHandle,
        email: normalizedEmail,
      );
    }

    if (updates.isNotEmpty) {
      await ref.set(updates, SetOptions(merge: true));
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

  Future<void> refreshSearchKeywords(String uid, {
    String? username,
    String? handle,
    String? email,
  }) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    final valueUsername = username ?? data['username'] as String? ?? '';
    final valueHandle = handle ?? data['handle'] as String? ?? '';
    final valueEmail = email ?? data['email'] as String? ?? '';

    await _db.collection('users').doc(uid).set({
      'searchKeywords': _buildSearchKeywords(
        username: valueUsername,
        handle: valueHandle,
        email: valueEmail,
      ),
    }, SetOptions(merge: true));
  }

  List<String> _buildSearchKeywords({
    required String username,
    required String handle,
    required String email,
  }) {
    final keywords = <String>{};
    void addTokens(String value) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return;
      for (var i = 1; i <= normalized.length; i++) {
        keywords.add(normalized.substring(0, i));
      }
    }

    addTokens(username);
    addTokens(handle.startsWith('@') ? handle.substring(1) : handle);
    addTokens(email.split('@').first);
    return keywords.toList();
  }
}
