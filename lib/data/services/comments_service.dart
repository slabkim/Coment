import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String titleId;
  final String userId;
  final String text;
  final String? imageUrl;
  final int likeCount;
  final int replyCount;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.titleId,
    required this.userId,
    required this.text,
    this.imageUrl,
    required this.likeCount,
    required this.replyCount,
    required this.createdAt,
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> m) => CommentModel(
        id: id,
        titleId: m['titleId'] as String,
        userId: m['userId'] as String,
        text: (m['text'] ?? '') as String,
        imageUrl: m['imageUrl'] as String?,
        likeCount: (m['likeCount'] as num?)?.toInt() ?? 0,
        replyCount: (m['replyCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['createdAt'] as num).toInt()),
      );

  Map<String, dynamic> toMap() => {
        'titleId': titleId,
        'userId': userId,
        'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'likeCount': likeCount,
        'replyCount': replyCount,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}

class CommentsService {
  final FirebaseFirestore _db;
  CommentsService([FirebaseFirestore? db]) : _db = db ?? FirebaseFirestore.instance;

  Stream<List<CommentModel>> watchComments(String titleId) {
    return _db
        .collection('comments')
        .where('titleId', isEqualTo: titleId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => CommentModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> addComment({required String titleId, required String userId, required String text, String? imageUrl}) async {
    await _db.collection('comments').add({
      'titleId': titleId,
      'userId': userId,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'likeCount': 0,
      'replyCount': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> like({required String commentId, required String userId}) async {
    // create like doc; rules enforce owner
    final like = await _db
        .collection('comment_likes')
        .where('commentId', isEqualTo: commentId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (like.docs.isEmpty) {
      await _db.collection('comment_likes').add({
        'commentId': commentId,
        'userId': userId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      await _db.collection('comments').doc(commentId).update({'likeCount': FieldValue.increment(1)});
    }
  }

  Future<void> unlike({required String commentId, required String userId}) async {
    final like = await _db
        .collection('comment_likes')
        .where('commentId', isEqualTo: commentId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (like.docs.isNotEmpty) {
      await _db.collection('comment_likes').doc(like.docs.first.id).delete();
      await _db.collection('comments').doc(commentId).update({'likeCount': FieldValue.increment(-1)});
    }
  }

  Stream<bool> isLiked({required String commentId, required String userId}) {
    return _db
        .collection('comment_likes')
        .where('commentId', isEqualTo: commentId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isNotEmpty);
  }
}


