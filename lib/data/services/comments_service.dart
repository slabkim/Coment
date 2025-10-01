import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String titleId;
  final String userId;
  final String text;
  final String? imageUrl;
  final int likeCount;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatar;
  final String? parentId;
  final List<dynamic> replies;

  const CommentModel({
    required this.id,
    required this.titleId,
    required this.userId,
    required this.text,
    this.imageUrl,
    required this.likeCount,
    required this.createdAt,
    this.userName,
    this.userAvatar,
    this.parentId,
    this.replies = const [],
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> m) {
    final created = (m['createdAt'] ?? m['timestamp']) as num?;
    final dt = created != null
        ? DateTime.fromMillisecondsSinceEpoch(created.toInt())
        : DateTime.now();
    final text = (m['text'] ?? m['commentText'] ?? '').toString();
    final image = (m['imageUrl'] ?? m['gifUrl'])?.toString();
    return CommentModel(
      id: id,
      titleId: (m['titleId'] ?? '') as String,
      userId: (m['userId'] ?? '') as String,
      text: text,
      imageUrl: (image != null && image.isNotEmpty) ? image : null,
      likeCount: (m['likeCount'] as num?)?.toInt() ?? 0,
      createdAt: dt,
      userName: (m['userName'] ?? m['username']) as String?,
      userAvatar: (m['userAvatar'] ?? m['avatarUrl']) as String?,
      parentId: (m['parentId'] as String?)?.isEmpty == true
          ? null
          : m['parentId'] as String?,
      replies: (m['replies'] as List<dynamic>?) ?? const [],
    );
  }
}

class CommentsService {
  final FirebaseFirestore _db;
  CommentsService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  Stream<List<CommentModel>> watchComments(String titleId) {
    return _db
        .collection('comments')
        .where('titleId', isEqualTo: titleId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => CommentModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> addComment({
    required String titleId,
    required String userId,
    required String text,
    String? imageUrl,
    String? userName,
    String? userAvatar,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final doc = _db.collection('comments').doc();
    await doc.set({
      'id': doc.id,
      'titleId': titleId,
      'userId': userId,
      'commentText': text,
      'gifUrl': imageUrl ?? '',
      'likeCount': 0,
      'parentId': '',
      'replies': const [],
      'timestamp': now,
      'createdAt': now,
      'userName': userName ?? 'Anon',
      'userAvatar': userAvatar ?? '',
      'userNameParent': null,
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
      await _db.collection('comments').doc(commentId).update({
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> unlike({
    required String commentId,
    required String userId,
  }) async {
    final like = await _db
        .collection('comment_likes')
        .where('commentId', isEqualTo: commentId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (like.docs.isNotEmpty) {
      await _db.collection('comment_likes').doc(like.docs.first.id).delete();
      await _db.collection('comments').doc(commentId).update({
        'likeCount': FieldValue.increment(-1),
      });
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
