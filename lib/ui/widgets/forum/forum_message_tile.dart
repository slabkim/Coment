import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants.dart';
import '../../../core/logger.dart';
import '../../../core/forum_username_lookup.dart';
import '../../../data/models/forum_message.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/user_role.dart';
import '../../../data/services/forum_message_service.dart';
import '../../../data/services/user_service.dart';
import '../../widgets/class_badge.dart';
import '../../screens/user_public_profile_screen.dart';
import '../common/identity_badge.dart';

/// Widget for displaying an individual forum message.
/// Includes user info, reply indicators, reactions, and action buttons.
class ForumMessageTile extends StatefulWidget {
  final ForumMessage message;
  final String forumId;
  final bool isPinned;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final Function(ForumMessage) onReply;

  const ForumMessageTile({
    super.key,
    required this.message,
    required this.forumId,
    required this.isPinned,
    required this.onPin,
    required this.onDelete,
    required this.onReply,
  });

  @override
  State<ForumMessageTile> createState() => _ForumMessageTileState();
}

class _ForumMessageTileState extends State<ForumMessageTile> {
  final _messageService = ForumMessageService();

  Future<void> _toggleReaction(String emoji) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    try {
      await _messageService.toggleReaction(widget.message.id, userId, emoji);
    } catch (e, stackTrace) {
      AppLogger.firebaseError('toggling reaction', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding reaction: $e')),
        );
      }
    }
  }

  List<Widget> _buildIdentityBadges({
    required bool isAdmin,
    required bool isDeveloper,
  }) {
    final widgets = <Widget>[];
    void addBadge(IdentityBadgeType type) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(width: 4));
      widgets.add(IdentityBadge(
        type: type,
        size: IdentityBadgeSize.compact,
      ));
    }

    if (isAdmin) addBadge(IdentityBadgeType.admin);
    if (isDeveloper) addBadge(IdentityBadgeType.developer);
    return widgets;
  }

  void _showReactionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        const emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏', '🎉'];
        
        return SafeArea(
          top: false,
          child: SingleChildScrollView(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: emojis.map((emoji) {
                return InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _toggleReaction(emoji);
                  },
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                );
              }).toList(),
            ),
          ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onLongPress: () => _showOptions(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            _buildAvatar(),
            
            const SizedBox(width: 12),
            
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info with class badge
                  _buildUserInfo(),
                  
                  const SizedBox(height: 4),
                  
                  // Reply preview (if this is a reply)
                  if (widget.message.replyTo != null)
                    _buildMessageReplyIndicator(),
                  
                  // Message text with mentions highlighted
                  if (widget.message.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildMessageText(),
                    ),
                  
                  // Image attachment
                  if (widget.message.imageUrl != null)
                    _buildImage(),
                  
                  // GIF attachment
                  if (widget.message.gifUrl != null)
                    _buildGif(),
                  
                  // Reactions
                  if (widget.message.reactions != null && widget.message.reactions!.isNotEmpty)
                    _buildReactions(),
                  
                  // Action buttons (reply, react)
                  _buildActionButtons(),
                ],
              ),
            ),
            
            // Pin indicator
            if (widget.isPinned)
              Icon(
                Icons.push_pin,
                size: 16,
                color: AppColors.purpleAccent,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundImage: widget.message.userAvatar != null
          ? CachedNetworkImageProvider(widget.message.userAvatar!)
          : null,
      onBackgroundImageError: widget.message.userAvatar != null
          ? (exception, stackTrace) {
              AppLogger.warning('Avatar load error', exception, stackTrace);
            }
          : null,
      child: widget.message.userAvatar == null
          ? Text(
              widget.message.userName.isNotEmpty 
                  ? widget.message.userName[0].toUpperCase() 
                  : '?',
              style: const TextStyle(fontSize: 16),
            )
          : null,
    );
  }

  Widget _buildUserInfo() {
    return StreamBuilder<UserProfile?>(
      stream: UserService().watchProfile(widget.message.userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final isDev = profile?.isDeveloper ?? false;
        final isAdmin = profile?.role == UserRole.admin;
        final userClass = profile?.userClass;
        
        return Row(
          children: [
            // Username
            Flexible(
              child: Text(
                widget.message.userName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            ..._buildIdentityBadges(
              isAdmin: isAdmin,
              isDeveloper: isDev,
            ),
            
            // Class badge
            if (userClass != null) ...[
              const SizedBox(width: 4),
              CompactClassBadge(
                userClass: userClass,
                size: 14,
              ),
            ],
            
            const SizedBox(width: 8),
            
            // Timestamp
            Text(
              _formatTime(widget.message.timestamp),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessageReplyIndicator() {
    if (widget.message.replyTo == null) return const SizedBox.shrink();
    
    return FutureBuilder<ForumMessage?>(
      future: _getReplyMessage(widget.message.replyTo!),
      builder: (context, snapshot) {
        String replyText = 'Replied to a message';
        String replyUser = '';
        
        if (snapshot.hasData && snapshot.data != null) {
          final reply = snapshot.data!;
          replyUser = reply.userName;
          
          if (reply.text.isNotEmpty) {
            replyText = reply.text.length > 40 
                ? '${reply.text.substring(0, 40)}...' 
                : reply.text;
          } else if (reply.imageUrl != null) {
            replyText = '📷 Photo';
          } else if (reply.gifUrl != null) {
            replyText = '🎬 GIF';
          }
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: AppColors.purpleAccent.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.reply,
                    size: 12,
                    color: AppColors.purpleAccent.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  if (replyUser.isNotEmpty)
                    Text(
                      'Replying to $replyUser',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? const Color(0xFF3B82F6)
                            : AppColors.purpleAccent.withOpacity(0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              if (snapshot.hasData && snapshot.data != null) ...[
                const SizedBox(height: 2),
                Text(
                  replyText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<ForumMessage?> _getReplyMessage(String messageId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('forum_messages')
          .doc(messageId)
          .get();
      
      if (doc.exists) {
        return ForumMessage.fromMap(doc.id, doc.data()!);
      }
    } catch (e, stackTrace) {
      AppLogger.firebaseError('fetching reply message', e, stackTrace);
    }
    return null;
  }

  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.message.imageUrl!,
          fit: BoxFit.cover,
          maxHeightDiskCache: 800,
          placeholder: (context, url) => Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildGif() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: widget.message.gifUrl!,
          fit: BoxFit.cover,
          maxHeightDiskCache: 800,
          placeholder: (context, url) => Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Loading GIF...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Icon(Icons.error),
          ),
        ),
      ),
    );
  }

  Widget _buildReactions() {
    final reactions = widget.message.reactions;
    if (reactions == null || reactions.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: reactions.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          final hasReacted = currentUserId != null && users.contains(currentUserId);
          
          return InkWell(
            onTap: () => _toggleReaction(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: hasReacted
                    ? AppColors.purpleAccent.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasReacted
                      ? AppColors.purpleAccent
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${users.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: hasReacted ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageText() {
    final text = widget.message.text;
    final mentionRegex = RegExp(r'(@\w+)');
    final matches = mentionRegex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
      );
    }
    
    // Build TextSpans with highlighted mentions
    final spans = <InlineSpan>[];
    int lastMatchEnd = 0;
    
    for (final match in matches) {
      // Add text before mention
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ));
      }
      
      // Add clickable mention
      final mentionText = match.group(0)!;
      final username = match.group(0)!.substring(1); // Remove @ symbol
      
      spans.add(
        WidgetSpan(
          child: FutureBuilder<String?>(
            future: ForumUsernameLookup.getUserIdByUsername(username, widget.forumId),
            builder: (context, snapshot) {
              final userId = snapshot.data;
              final isValidUser = userId != null;
              
              return GestureDetector(
                onTap: isValidUser
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserPublicProfileScreen(userId: userId),
                          ),
                        );
                      }
                    : null,
                child: Text(
                  mentionText,
                  style: TextStyle(
                    color: isValidUser
                        ? (Theme.of(context).brightness == Brightness.light
                            ? Colors.black87
                            : Colors.white)
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isValidUser ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              );
            },
          ),
        ),
      );
      
      lastMatchEnd = match.end;
    }
    
    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14),
        children: spans,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => widget.onReply(widget.message),
          icon: Icon(
            Icons.reply,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          label: Text(
            'Reply',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _showReactionPicker,
          icon: Icon(
            Icons.add_reaction,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          label: Text(
            'React',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(50, 24),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply option
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onReply(widget.message);
                },
              ),
              // Pin option
              if (!widget.isPinned)
                ListTile(
                  leading: const Icon(Icons.push_pin),
                  title: const Text('Pin Message'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onPin();
                  },
                ),
              if (widget.isPinned)
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: const Text('Unpin Message'),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onPin();
                  },
                ),
              // Delete option
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete();
                },
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    
    return '${time.day}/${time.month}/${time.year}';
  }
}

