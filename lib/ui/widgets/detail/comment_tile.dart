import 'package:flutter/material.dart';

import '../../../core/auth_helper.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/comments_service.dart';
import '../../../data/services/user_service.dart';
import '../../screens/user_public_profile_screen.dart';
import '../class_badge.dart';

/// Single Comment Tile Widget
class CommentTile extends StatelessWidget {
  final CommentModel model;
  final String? uid;
  final CommentsService svc;
  final VoidCallback? onReply;
  final bool isReply;
  
  const CommentTile({
    super.key,
    required this.model,
    required this.uid,
    required this.svc,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final likeLabel = '${model.likeCount} likes';
    final timeLabel = _timeAgo(model.createdAt);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: isReply 
            ? Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar + Name + Time
            Row(
              children: [
                CircleAvatar(
                  radius: isReply ? 14 : 18,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  backgroundImage:
                      (model.userAvatar != null && model.userAvatar!.isNotEmpty)
                      ? NetworkImage(model.userAvatar!)
                      : null,
                  child: (model.userAvatar == null || model.userAvatar!.isEmpty)
                      ? Text(
                          _initials(model.userName),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: isReply ? 10 : 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username with Dev Badge & Class Badge
                      StreamBuilder<UserProfile?>(
                        stream: UserService().watchProfile(model.userId),
                        builder: (context, profileSnapshot) {
                          final profile = profileSnapshot.data;
                          final isDev = profile?.isDeveloper ?? false;
                          final userClass = profile?.userClass;
                          
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  model.userName ?? 'Anon',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isReply ? 13 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDev) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified, size: 8, color: Colors.white),
                                      SizedBox(width: 2),
                                      Text(
                                        'DEV',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (userClass != null) ...[
                                const SizedBox(width: 4),
                                CompactClassBadge(
                                  userClass: userClass,
                                  size: isReply ? 16 : 18,
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Like button
                if (uid != null)
                  StreamBuilder<bool>(
                    stream: svc.isLiked(commentId: model.id, userId: uid!),
                    builder: (context, snap) {
                      final liked = snap.data ?? false;
                      return IconButton(
                        icon: Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          size: isReply ? 16 : 18,
                        ),
                        color: liked ? Colors.pinkAccent : Theme.of(context).colorScheme.onSurfaceVariant,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final success = await AuthHelper.requireAuthWithDialog(
                            context, 
                            'like this comment'
                          );
                          if (success && uid != null) {
                            if (liked) {
                              await svc.unlike(commentId: model.id, userId: uid!);
                            } else {
                              await svc.like(commentId: model.id, userId: uid!);
                            }
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
            
            // Comment text
            if (model.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (model.userId.isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserPublicProfileScreen(userId: model.userId),
                    ),
                  );
                },
                child: Text(
                  model.text,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: isReply ? 13 : 14,
                  ),
                ),
              ),
            ],
            
            // Image
            if (model.imageUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  model.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            
            // Footer: Likes + Reply button
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  likeLabel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (onReply != null && !isReply) ...[
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: onReply,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.reply,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reply',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + second).toUpperCase();
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return '${weeks}w ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo ago';
    final years = (diff.inDays / 365).floor();
    return '${years}y ago';
  }
}

