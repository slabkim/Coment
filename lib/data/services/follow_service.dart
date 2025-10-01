import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _db;
  FollowService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> followers(String userId) {
    return _db
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> following(String userId) {
    return _db
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> toggleFollow({required String followerId, required String followingId}) async {
    if (followerId == followingId) return;
    final q = await _db
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      await _db.collection('follows').doc(q.docs.first.id).delete();
    } else {
      await _db.collection('follows').add({
        'followerId': followerId,
        'followingId': followingId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}


