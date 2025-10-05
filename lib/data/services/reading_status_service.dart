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
    print('🔄 ReadingStatusService.setStatus called:');
    print('   userId: $userId');
    print('   titleId: $titleId');
    print('   status: $status');
    
    try {
      final q = await _db
          .collection('reading_status')
          .where('userId', isEqualTo: userId)
          .where('titleId', isEqualTo: titleId)
          .limit(1)
          .get();
      
      print('   Query result: ${q.docs.length} documents found');
      
      if (q.docs.isNotEmpty) {
        print('   Updating existing document: ${q.docs.first.id}');
        await _db.collection('reading_status').doc(q.docs.first.id).update({
          fieldStatus: status,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('   ✅ Document updated successfully');
      } else {
        print('   Creating new document');
        final docRef = await _db.collection('reading_status').add({
          'userId': userId,
          'titleId': titleId,
          fieldStatus: status,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('   ✅ New document created with ID: ${docRef.id}');
      }
    } catch (e) {
      print('   ❌ Error in setStatus: $e');
      rethrow;
    }
  }

  /// Watch all title IDs for a given user and status.
  Stream<List<String>> watchTitlesByStatus({
    required String userId,
    required String status,
  }) {
    print('🔍 watchTitlesByStatus called:');
    print('   userId: $userId');
    print('   status: $status');
    
    return _db
        .collection('reading_status')
        .where('userId', isEqualTo: userId)
        .where(fieldStatus, isEqualTo: status)
        .snapshots()
        .map((s) {
          final titleIds = s.docs.map((d) => (d.data()['titleId'] as String)).toList();
          print('   Found ${titleIds.length} titles with status $status: $titleIds');
          return titleIds;
        });
  }

  /// Watch all title IDs for a user with any reading status (WANT_TO_READ, READING, COMPLETED, DROPPED, PAUSED).
  Stream<List<String>> watchAllReadingTitles(String userId) {
    print('🔍 watchAllReadingTitles called:');
    print('   userId: $userId');
    
    return _db
        .collection('reading_status')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((s) {
          print('   Raw documents found: ${s.docs.length}');
          for (int i = 0; i < s.docs.length; i++) {
            final doc = s.docs[i];
            final data = doc.data();
            print('   Doc $i: titleId=${data['titleId']}, status=${data['status']}, docId=${doc.id}');
          }
          
          final titleIds = s.docs.map((d) => (d.data()['titleId'] as String)).toList();
          final uniqueTitleIds = titleIds.toSet().toList();
          
          print('   All titleIds: $titleIds');
          print('   Unique titleIds: $uniqueTitleIds');
          print('   Total count: ${titleIds.length}, Unique count: ${uniqueTitleIds.length}');
          
          // Return unique title IDs to avoid duplicates
          return uniqueTitleIds;
        });
  }
}
