import 'package:cloud_firestore/cloud_firestore.dart';

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
        'photoUrl': photoUrl ?? '',
        'bio': '',
        'joinAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}


