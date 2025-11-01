import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/auth_helper.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/comments_service.dart';
import '../../../data/services/user_service.dart';
import 'comment_with_replies.dart';

/// Comments Tab for Detail Screen
class CommentsTab extends StatefulWidget {
  final String titleId;
  
  const CommentsTab({
    super.key,
    required this.titleId,
  });

  @override
  State<CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<CommentsTab> {
  final _c = TextEditingController();
  final _svc = CommentsService();
  CommentModel? _replyingTo;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reply indicator
              if (_replyingTo != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Replying to ${_replyingTo!.userName ?? 'Anon'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() => _replyingTo = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Comment input
              Row(
                children: [
                  // User avatar
                  StreamBuilder<UserProfile?>(
                    stream: uid != null ? UserService().watchProfile(uid) : null,
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final photoUrl = profile?.photoUrl;
                      
                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Icon(
                                Icons.person,
                                color: Theme.of(context).colorScheme.onSurface,
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _c,
                      minLines: 1,
                      maxLines: 3,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: _replyingTo == null ? 'Add a comment...' : 'Write a reply...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _post(uid),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _post(uid),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Post'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<CommentModel>>(
            stream: _svc.watchTopLevelComments(widget.titleId),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No comments yet. Be the first to comment!',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final m = items[i];
                  return CommentWithReplies(
                    model: m,
                    uid: uid,
                    svc: _svc,
                    onReply: (comment) {
                      setState(() => _replyingTo = comment);
                      _c.clear();
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _post(String? uid) async {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    
    // Cek autentikasi dulu
    final success = await AuthHelper.requireAuthWithDialog(
      context, 
      _replyingTo == null ? 'post a comment' : 'reply to this comment'
    );
    if (!success) return;
    
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    
    final user = FirebaseAuth.instance.currentUser;
    await _svc.addComment(
      titleId: widget.titleId,
      userId: currentUid,
      text: text,
      userName: user?.displayName,
      userAvatar: user?.photoURL,
      parentId: _replyingTo?.id,
      replyToUserId: _replyingTo?.userId,
      replyToUserName: _replyingTo?.userName,
    );
    _c.clear();
    setState(() => _replyingTo = null);
  }
}

