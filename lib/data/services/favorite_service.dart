import 'package:cloud_firestore/cloud_firestore.dart';
import 'xp_service.dart';

class FavoriteService {
  final FirebaseFirestore _db;
  final XPService _xpService;
  
  FavoriteService([FirebaseFirestore? db, XPService? xpService])
    : _db = db ?? FirebaseFirestore.instance,
      _xpService = xpService ?? XPService();

  Stream<bool> isFavoriteStream({
    required String userId,
    required String titleId,
  }) {
    return _db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('titleId', isEqualTo: titleId)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isNotEmpty);
  }

  Future<void> toggleFavorite({
    required String userId,
    required String titleId,
  }) async {
    final q = await _db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('titleId', isEqualTo: titleId)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      // Remove favorite
      await _db.collection('favorites').doc(q.docs.first.id).delete();
      
      // Award negative XP for removing favorite
      await _xpService.penalizeRemoveFavorite(userId, titleId);
    } else {
      // Add favorite
      await _db.collection('favorites').add({
        'userId': userId,
        'titleId': titleId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Award XP for adding favorite
      await _xpService.awardAddFavorite(userId, titleId);
    }
  }

  /// Watch all favorite title IDs for a user.
  Stream<List<String>> watchFavorites(String userId) {
    return _db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) => s.docs.map((d) => (d.data()['titleId'] as String)).toList());
  }
}
