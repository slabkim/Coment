import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart' as rx;

import '../models/announcement.dart';
import '../models/audit_log.dart';
import '../models/report.dart';
import '../models/room.dart';
import '../models/room_member.dart';
import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../models/user_sanction.dart';

/// Centralized gateway for admin-only Firestore queries and callable functions.
class AdminService {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final String _region;

  AdminService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    String region = 'asia-southeast2',
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _region = region;

  /// Watch paginated user list with optional filters and robust search.
  Stream<List<UserProfile>> watchUsers({
    UserRole? role,
    UserStatus? status,
    String? search,
    int limit = 200,
  }) {
    final hasSearch = search != null && search.trim().isNotEmpty;
    // Base query builder to apply role/status filters consistently
    Query<Map<String, dynamic>> base = _db.collection('users');
    if (role != null) {
      base = base.where('role', isEqualTo: role.asValue);
    }
    if (status != null) {
      base = base.where('status', isEqualTo: status.asValue);
    }

    // No search: stream latest users
    if (!hasSearch) {
      final query = base.orderBy('joinAt', descending: true).limit(limit);
      return query.snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => UserProfile.fromMap(doc.id, doc.data()))
            .toList(),
      );
    }

    // With search: combine multiple strategies + fallback
    final q = search.trim().toLowerCase();

    // searchKeywords token-based (fallback, newer users)
    final keywordStream = base
        .where('searchKeywords', arrayContains: q)
        .limit(limit)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => UserProfile.fromMap(d.id, d.data())).toList(),
        );

    // usernameLower prefix search
    final usernameStream = base
        .where('usernameLower', isGreaterThanOrEqualTo: q)
        .where('usernameLower', isLessThan: '$q~')
        .limit(limit)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => UserProfile.fromMap(d.id, d.data())).toList(),
        );

    // handleLower prefix search
    final handleStream = base
        .where('handleLower', isGreaterThanOrEqualTo: q)
        .where('handleLower', isLessThan: '$q~')
        .limit(limit)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => UserProfile.fromMap(d.id, d.data())).toList(),
        );

    // Recent users fallback (client-side filtering) to catch older docs without index fields
    final recentStream = base
        .orderBy('joinAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (s) => s.docs.map((d) => UserProfile.fromMap(d.id, d.data())).where((
            u,
          ) {
            final uname = (u.username ?? '').toLowerCase();
            final handle = (u.handle ?? '').toLowerCase();
            final email = (u.email ?? '').toLowerCase();
            return uname.contains(q) || handle.contains(q) || email.contains(q);
          }).toList(),
        );

    return rx.CombineLatestStream.list<List<UserProfile>>([
      keywordStream,
      usernameStream,
      handleStream,
      recentStream,
    ]).map((lists) {
      final merged = <String, UserProfile>{};
      for (final list in lists) {
        for (final u in list) {
          merged[u.id] = u;
        }
      }
      final result = merged.values.toList();
      result.sort((a, b) {
        final av = a.joinedAt?.millisecondsSinceEpoch ?? 0;
        final bv = b.joinedAt?.millisecondsSinceEpoch ?? 0;
        return bv.compareTo(av);
      });
      return result.length > limit ? result.sublist(0, limit) : result;
    });
  }

  /// Fetch sanction history for a specific user.
  Stream<List<UserSanction>> watchUserSanctions(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('sanctions')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(UserSanction.fromDoc).toList());
  }

  /// Watch audit logs with optional filters.
  Stream<List<AuditLogEntry>> watchAuditLogs({
    String? actorId,
    String? action,
    DateTime? since,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('audit_logs')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (actorId != null) {
      query = query.where('actorId', isEqualTo: actorId);
    }
    if (action != null) {
      query = query.where('action', isEqualTo: action);
    }
    if (since != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(since),
      );
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(AuditLogEntry.fromDoc).toList(),
    );
  }

  /// Callable wrappers -------------------------------------------------------

  Future<Map<String, dynamic>> _callFunction(
    String name,
    Map<String, dynamic> data,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be logged in to manage admin data.');
    }
    // Force refresh token to ensure latest custom claims are present
    await user.getIdToken(true);
    final functions = FirebaseFunctions.instanceFor(region: _region);
    try {
      final res = await functions.httpsCallable(name).call(data);
      final payload = res.data;
      if (payload is Map<String, dynamic>) return payload;
      return {'result': payload};
    } catch (e) {
      // Fallback for platforms where cloud_functions plugin is unavailable (e.g., desktop)
      final msg = e.toString();
      final channelIssue =
          msg.contains('cloud_functions_platform_interface') ||
          msg.contains('CloudFunctionsHostApi.call') ||
          msg.contains('MissingPluginException') ||
          msg.contains('PlatformException(unimplemented');

      if (!channelIssue) {
        if (e is FirebaseFunctionsException) {
          throw Exception(
            'Function $name failed (${e.code}): ${e.message ?? e.details ?? 'Unknown error'}',
          );
        }
        rethrow;
      }

      // HTTP fallback to callable endpoint
      final projectId = Firebase.app().options.projectId;
      if (projectId.isEmpty) {
        throw StateError('Firebase projectId is not configured.');
      }
      final idToken = await user.getIdToken(true);
      final url = Uri.parse(
        'https://$_region-$projectId.cloudfunctions.net/$name',
      );
      final resp = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({'data': data}),
      );
      if (resp.statusCode >= 400) {
        throw Exception(
          'Function $name failed (${resp.statusCode}): ${resp.body}',
        );
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) {
        final result = decoded['result'];
        if (result is Map<String, dynamic>) return result;
        return decoded;
      }
      return {};
    }
  }

  Future<void> setUserRole({
    required String userId,
    required UserRole role,
    String? reason,
  }) async {
    await _callFunction('adminSetUserRole', {
      'userId': userId,
      'role': role.asValue,
      if (reason != null) 'reason': reason,
    });
  }

  Future<void> muteUser({
    required String userId,
    required Duration duration,
    String? reason,
    bool global = true,
  }) async {
    await _callFunction('adminMuteUser', {
      'userId': userId,
      'durationMinutes': duration.inMinutes,
      'reason': reason,
      'global': global,
    });
  }

  Future<void> unmuteUser(String userId) async {
    // Debug log to ensure client auth/token is present before calling the function.
    final user = _auth.currentUser;
    print('adminUnmuteUser currentUser uid=${user?.uid}');
    final token = await user?.getIdToken(true);
    print('adminUnmuteUser idToken length=${token?.length}');

    await _callFunction('adminUnmuteUser', {'userId': userId});
  }

  Future<void> banUser({
    required String userId,
    String? reason,
    Duration? duration,
  }) async {
    await _callFunction('adminBanUser', {
      'userId': userId,
      'reason': reason,
      if (duration != null) 'durationMinutes': duration.inMinutes,
    });
  }

  Future<void> unbanUser(String userId) async {
    await _callFunction('adminUnbanUser', {'userId': userId});
  }

  Future<void> shadowBanUser({
    required String userId,
    bool enabled = true,
    String? reason,
  }) async {
    await _callFunction('adminShadowBanUser', {
      'userId': userId,
      'enabled': enabled,
      if (reason != null) 'reason': reason,
    });
  }

  /// Rooms -------------------------------------------------------------------

  Stream<List<Room>> watchRooms({RoomVisibility? visibility, int limit = 50}) {
    Query<Map<String, dynamic>> query = _db
        .collection('rooms')
        .orderBy('memberCount', descending: true)
        .limit(limit);

    if (visibility != null) {
      query = query.where('visibility', isEqualTo: visibility.asValue);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(Room.fromDoc).toList(),
    );
  }

  Stream<List<RoomMember>> watchRoomMembers(String roomId) {
    return _db
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(RoomMember.fromDoc).toList());
  }

  Future<void> saveRoom(Room room, {String? passcode}) async {
    final payload = room.toMap()..['id'] = room.id;
    if (passcode != null && passcode.isNotEmpty) {
      payload['passcode'] = passcode;
    }
    await _callFunction('adminSaveRoom', {'room': payload});
  }

  Future<void> deleteRoom(String roomId) async {
    await _callFunction('adminDeleteRoom', {'roomId': roomId});
  }

  Future<void> assignRoomModerator({
    required String roomId,
    required String userId,
    required bool add,
  }) async {
    await _callFunction('adminAssignRoomModerator', {
      'roomId': roomId,
      'userId': userId,
      'add': add,
    });
  }

  Future<void> muteRoomMember({
    required String roomId,
    required String userId,
    Duration? duration,
    String? reason,
  }) async {
    await _callFunction('adminMuteRoomMember', {
      'roomId': roomId,
      'userId': userId,
      'durationMinutes': duration?.inMinutes,
      'reason': reason,
    });
  }

  Future<void> kickRoomMember({
    required String roomId,
    required String userId,
    String? reason,
  }) async {
    await _callFunction('adminKickRoomMember', {
      'roomId': roomId,
      'userId': userId,
      'reason': reason,
    });
  }

  Future<void> clearRoomMessages({required String roomId, int? limit}) async {
    await _callFunction('adminClearRoomMessages', {
      'roomId': roomId,
      if (limit != null) 'limit': limit,
    });
  }

  /// Reports -----------------------------------------------------------------

  Stream<List<ReportItem>> watchReports({
    ReportStatus? status,
    String? roomId,
    String? targetUserId,
    int limit = 100,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status.asValue);
    }
    if (roomId != null) {
      query = query.where('roomId', isEqualTo: roomId);
    }
    if (targetUserId != null) {
      query = query.where('targetUserId', isEqualTo: targetUserId);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(ReportItem.fromDoc).toList(),
    );
  }

  Future<void> assignReport({
    required String reportId,
    required String adminId,
  }) async {
    await _callFunction('adminAssignReport', {
      'reportId': reportId,
      'adminId': adminId,
    });
  }

  Future<void> resolveReport({
    required String reportId,
    required ReportStatus status,
    String? resolutionNotes,
    Map<String, dynamic>? actions,
  }) async {
    await _callFunction('adminResolveReport', {
      'reportId': reportId,
      'status': status.asValue,
      if (resolutionNotes != null) 'notes': resolutionNotes,
      if (actions != null) 'actions': actions,
    });
  }

  /// Announcements -----------------------------------------------------------

  Stream<List<Announcement>> watchAnnouncements({int limit = 50}) {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Announcement.fromDoc).toList());
  }

  Future<void> saveAnnouncement(Announcement announcement) async {
    await _callFunction('adminSaveAnnouncement', {
      'announcement': announcement.toMap()..['id'] = announcement.id,
    });
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _callFunction('adminDeleteAnnouncement', {
      'announcementId': announcementId,
    });
  }

  /// Populate searchKeywords for existing users
  Future<void> populateSearchKeywords() async {
    final usersSnapshot = await _db.collection('users').get();
    final batch = _db.batch();

    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      final username = data['username'] as String? ?? '';
      final handle = data['handle'] as String? ?? '';
      final email = data['email'] as String? ?? '';

      final keywords = _buildSearchKeywords(
        username: username,
        handle: handle,
        email: email,
      );

      batch.update(doc.reference, {'searchKeywords': keywords});
    }

    await batch.commit();
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
