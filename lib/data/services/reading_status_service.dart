import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingStatusService {
  final FirebaseFirestore _db;
  ReadingStatusService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

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
    final q = await _db
        .collection('reading_status')
        .where('userId', isEqualTo: userId)
        .where('titleId', isEqualTo: titleId)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
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
  }
}
