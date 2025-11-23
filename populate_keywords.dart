import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  await Firebase.initializeApp();
  final db = FirebaseFirestore.instance;

  print('Starting to populate searchKeywords for all users...');

  final usersSnapshot = await db.collection('users').get();
  final batch = db.batch();
  int count = 0;

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
    count++;
  }

  await batch.commit();
  print('Updated $count users with searchKeywords');
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
