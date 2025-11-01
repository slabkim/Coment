import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';
import 'xp_service.dart';

class ReadingStatusService {
  final FirebaseFirestore _db;
  final XPService _xpService;
  
  ReadingStatusService([FirebaseFirestore? db, XPService? xpService])
    : _db = db ?? FirebaseFirestore.instance,
      _xpService = xpService ?? XPService();

  // values example: plan, reading, completed, dropped, on_hold
  static const fieldStatus = 'status';

  Stream<String?> watchStatus({
    required String userId,
    required String titleId,
  }) {
    return _db
        .collection('reading_status')
        .where('userId', isEqualTo: userId)
        .where('titleId', isEqualTo: titleId)
        .limit(1)
        .snapshots()
        .map(
          (s) => s.docs.isEmpty
              ? null
              : (s.docs.first.data()[fieldStatus] as String?),
        );
  }

  Future<void> setStatus({
    required String userId,
    required String titleId,
    required String status,
  }) async {
    try {
      final q = await _db
          .collection('reading_status')
          .where('userId', isEqualTo: userId)
          .where('titleId', isEqualTo: titleId)
          .limit(1)
          .get();
      
      String? oldStatus;
      
      if (q.docs.isNotEmpty) {
        oldStatus = q.docs.first.data()[fieldStatus] as String?;
        
        await _db.collection('reading_status').doc(q.docs.first.id).update({
          fieldStatus: status,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        await _db.collection('reading_status').add({
          'userId': userId,
          'titleId': titleId,
          fieldStatus: status,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      
      // Award XP for completing a comic (if status changed to completed)
      if (status.toLowerCase() == 'completed' && oldStatus?.toLowerCase() != 'completed') {
        await _xpService.awardCompleteComic(userId, titleId);
      } else if (oldStatus != status) {
        // Award smaller XP for updating reading status
        await _xpService.awardUpdateReadingStatus(userId, titleId);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error in setStatus', e, stackTrace);
      rethrow;
    }
  }

  /// Watch all title IDs for a given user and status.
  Stream<List<String>> watchTitlesByStatus({
    required String userId,
    required String status,
  }) {
    return _db
        .collection('reading_status')
        .where('userId', isEqualTo: userId)
        .where(fieldStatus, isEqualTo: status)
        .snapshots()
        .map((s) => s.docs.map((d) => (d.data()['titleId'] as String)).toList());
  }

  /// Watch all title IDs for a user with any reading status (WANT_TO_READ, READING, COMPLETED, DROPPED, PAUSED).
  Stream<List<String>> watchAllReadingTitles(String userId) {
    return _db
        .collection('reading_status')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          final titleIds = s.docs.map((d) => (d.data()['titleId'] as String)).toList();
          return titleIds.toSet().toList(); // Return unique title IDs to avoid duplicates
        });
  }
}
