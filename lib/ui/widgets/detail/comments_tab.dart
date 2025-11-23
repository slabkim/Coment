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
  final UserService _userService = UserService();
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
          child: StreamBuilder<UserProfile?>(
            stream: uid != null ? _userService.watchProfile(uid) : null,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              return _buildComposer(profile, uid);
            },
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

  Widget _buildComposer(UserProfile? profile, String? uid) {
    final theme = Theme.of(context);
    final isMuted = profile?.isMuted ?? false;
    final muteMessage = isMuted && profile != null ? _buildMuteMessage(profile) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_replyingTo != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.reply, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replying to ${_replyingTo!.userName ?? 'Anon'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
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
        Row(
          children: [
            _buildAvatar(profile),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _c,
                minLines: 1,
                maxLines: 3,
                enabled: !isMuted,
                readOnly: isMuted,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: isMuted
                      ? 'You are muted and cannot comment right now.'
                      : (_replyingTo == null ? 'Add a comment...' : 'Write a reply...'),
                  hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: isMuted ? null : (_) => _post(uid, profile),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: isMuted ? null : () => _post(uid, profile),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Post'),
            ),
          ],
        ),
        if (muteMessage != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              muteMessage,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(UserProfile? profile) {
    final photoUrl = profile?.photoUrl;
    return CircleAvatar(
      radius: 18,
      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
      child: (photoUrl == null || photoUrl.isEmpty)
          ? Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onSurface,
            )
          : null,
    );
  }

  Future<void> _post(String? uid, [UserProfile? profile]) async {
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

    UserProfile? resolvedProfile = profile;
    if (resolvedProfile == null || resolvedProfile.id != currentUid) {
      try {
        resolvedProfile = await _userService.fetchProfile(currentUid);
      } catch (_) {}
    }

    if (resolvedProfile != null && resolvedProfile.isMuted) {
      _showMuteSnackBar(resolvedProfile);
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    await _svc.addComment(
      titleId: widget.titleId,
      userId: currentUid,
      text: text,
      userName: resolvedProfile?.username ?? user?.displayName,
      userAvatar: resolvedProfile?.photoUrl ?? user?.photoURL,
      parentId: _replyingTo?.id,
      replyToUserId: _replyingTo?.userId,
      replyToUserName: _replyingTo?.userName,
    );
    _c.clear();
    setState(() => _replyingTo = null);
  }

  void _showMuteSnackBar(UserProfile profile) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_buildMuteMessage(profile))),
    );
  }

  String _buildMuteMessage(UserProfile profile) {
    final reason = (profile.lastSanctionReason?.trim().isNotEmpty ?? false)
        ? profile.lastSanctionReason!.trim()
        : 'Akunmu sedang di-mute oleh admin.';
    final until = profile.mutedUntil;
    if (until == null) return reason;
    return '$reason (berlaku sampai ${_formatDateTime(until)})';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

