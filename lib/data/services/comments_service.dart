import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/logger.dart';
import 'xp_service.dart';

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
  final XPService _xpService;
  
  CommentsService([FirebaseFirestore? db, XPService? xpService])
    : _db = db ?? FirebaseFirestore.instance,
      _xpService = xpService ?? XPService();

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
    String? parentId,
    String? replyToUserId,
    String? replyToUserName,
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
      'parentId': parentId ?? '',
      'replies': const [],
      'timestamp': now,
      'createdAt': now,
      'userName': userName ?? 'Anon',
      'userAvatar': userAvatar ?? '',
      'userNameParent': replyToUserName,
      'replyToUserId': replyToUserId,
    });
    
    // If this is a reply, add to parent's replies array and send notification
    if (parentId != null && parentId.isNotEmpty) {
      await _db.collection('comments').doc(parentId).update({
        'replies': FieldValue.arrayUnion([doc.id]),
      });
      
      // Send notification to user being replied to
      if (replyToUserId != null && replyToUserId != userId) {
        await _sendReplyNotification(
          recipientUserId: replyToUserId,
          senderUserId: userId,
          senderName: userName ?? 'Someone',
          commentText: text,
          titleId: titleId,
        );
      }
      
      // Award XP for replying to a comment
      await _xpService.awardReplyComment(userId, parentId);
    } else {
      // Award XP for writing a top-level comment
      await _xpService.awardWriteComment(userId, titleId);
    }
  }
  
  /// Send notification when someone replies to a comment
  Future<void> _sendReplyNotification({
    required String recipientUserId,
    required String senderUserId,
    required String senderName,
    required String commentText,
    required String titleId,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': recipientUserId,
        'type': 'comment_reply',
        'senderId': senderUserId,
        'senderName': senderName,
        'message': '$senderName replied to your comment: ${commentText.length > 50 ? '${commentText.substring(0, 50)}...' : commentText}',
        'titleId': titleId,
        'read': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      // Log warning instead of silently failing
      // Notification failure shouldn't block comment creation
      AppLogger.warning('Failed to send comment reply notification', e);
    }
  }
  
  /// Get replies for a specific comment
  Stream<List<CommentModel>> watchReplies(String parentId) {
    return _db
        .collection('comments')
        .where('parentId', isEqualTo: parentId)
        .orderBy('timestamp', descending: false) // Replies oldest first
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => CommentModel.fromMap(d.id, d.data())).toList(),
        );
  }
  
  /// Get top-level comments only (no replies)
  Stream<List<CommentModel>> watchTopLevelComments(String titleId) {
    return _db
        .collection('comments')
        .where('titleId', isEqualTo: titleId)
        .where('parentId', isEqualTo: '')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => CommentModel.fromMap(d.id, d.data())).toList(),
        );
  }
  
  /// Delete a comment (also delete all its replies)
  Future<void> deleteComment(String commentId, String userId) async {
    final comment = await _db.collection('comments').doc(commentId).get();
    if (!comment.exists) return;
    
    final data = comment.data()!;
    // Only allow deletion by comment owner
    if (data['userId'] != userId) return;
    
    // Delete all replies first
    final replies = (data['replies'] as List<dynamic>?) ?? [];
    for (final replyId in replies) {
      await _db.collection('comments').doc(replyId).delete();
    }
    
    // Delete the comment itself
    await _db.collection('comments').doc(commentId).delete();
    
    // Remove from parent's replies array if this is a reply
    final parentId = data['parentId'];
    if (parentId != null && parentId.toString().isNotEmpty) {
      await _db.collection('comments').doc(parentId).update({
        'replies': FieldValue.arrayRemove([commentId]),
      });
    }
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
