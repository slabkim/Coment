import 'package:cloud_firestore/cloud_firestore.dart';

class FavoriteService {
  final FirebaseFirestore _db;
  FavoriteService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  Stream<bool> isFavoriteStream({required String userId, required String titleId}) {
    return _db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('titleId', isEqualTo: titleId)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isNotEmpty);
  }

  Future<void> toggleFavorite({required String userId, required String titleId}) async {
    final q = await _db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('titleId', isEqualTo: titleId)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      await _db.collection('favorites').doc(q.docs.first.id).delete();
    } else {
      await _db.collection('favorites').add({
        'userId': userId,
        'titleId': titleId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}


