import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../core/forum_username_lookup.dart';
import '../../data/models/forum.dart';
import '../../data/models/forum_message.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/forum_service.dart';
import '../../data/services/forum_message_service.dart';
import '../../data/services/forum_member_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/giphy_service.dart';
import '../widgets/forum/forum_message_tile.dart';
import '../widgets/forum/forum_message_input.dart';
import '../widgets/forum/pinned_messages_section.dart';

class ForumChatScreen extends StatefulWidget {
  final Forum forum;

  const ForumChatScreen({super.key, required this.forum});

  @override
  State<ForumChatScreen> createState() => _ForumChatScreenState();
}

class _ForumChatScreenState extends State<ForumChatScreen> {
  final _messageController = TextEditingController();
  final _forumService = ForumService();
  final _messageService = ForumMessageService();
  final _memberService = ForumMemberService();
  final _userService = UserService();
  final _imagePicker = ImagePicker();
  final _giphy = GiphyService();
  
  Stream<Forum?>? _forumStream;
  File? _selectedImage;
  String? _selectedGifUrl;
  ForumMessage? _replyingTo;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markAsRead();
    // Stream forum data for real-time updates (permissions, member count, etc)
    _forumStream = _forumService.watchForum(widget.forum.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    await _memberService.markAsRead(widget.forum.id, userId);
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _selectedGifUrl = null; // Clear GIF if image is selected
        });
      }
    } catch (e, stackTrace) {
      AppLogger.warning('Error picking image', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _pickGif(String url) async {
    if (url.isNotEmpty) {
      setState(() {
        _selectedGifUrl = url;
        _selectedImage = null; // Clear image if GIF is selected
      });
    }
    return url;
  }

  Future<String?> _uploadMessageImage(String messageId) async {
    if (_selectedImage == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('forum_message_images')
          .child(widget.forum.id)
          .child('$messageId.jpg');
      
      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();
      
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.firebaseError('uploading message image', e, stackTrace);
      return null;
    }
  }

  List<String> _extractMentions(String text) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }
  
  /// Send notifications to mentioned users
  Future<void> _sendMentionNotifications({
    required List<String> mentions,
    required String senderName,
    required String senderUid,
    required String messageText,
    required String forumId,
    required String forumName,
  }) async {
    try {
      for (final username in mentions) {
        // Find user ID by username (validate they're in the forum)
        final userId = await ForumUsernameLookup.getUserIdByUsername(username, forumId);
        
        if (userId == null) {
          continue;
        }
        
        // Don't notify yourself
        if (userId == senderUid) {
          continue;
        }
        
        // Create notification document in Firestore
        // Cloud Function will listen to this and send FCM
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'mention',
          'recipientUid': userId,
          'senderUid': senderUid,
          'senderName': senderName,
          'forumId': forumId,
          'forumName': forumName,
          'message': messageText.length > 100 ? '${messageText.substring(0, 100)}...' : messageText,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    } catch (e, stackTrace) {
      AppLogger.warning('Error sending mention notifications', e, stackTrace);
      // Don't throw - notification failure shouldn't block message sending
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null && _selectedGifUrl == null) return;
    
    // Prevent spam clicking
    if (_isSending) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isSending = true);
    
    try {
      final profile = await _userService.fetchProfile(user.uid);
      if (profile != null && profile.isMuted) {
        if (mounted) {
          _showMuteSnackBar(profile);
        }
        if (mounted) {
          setState(() => _isSending = false);
        }
        return;
      }
      
      // Extract mentions from text
      final mentions = _extractMentions(text);
      
      // Generate message ID first for image upload
      String? imageUrl;
      if (_selectedImage != null) {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await _uploadMessageImage(tempId);
      }
      
      await _messageService.sendMessage(
        forumId: widget.forum.id,
        userId: user.uid,
        userName: profile?.username ?? 'Anonymous',
        userAvatar: profile?.photoUrl,
        text: text.isNotEmpty ? text : null,
        imageUrl: imageUrl,
        gifUrl: _selectedGifUrl,
        replyTo: _replyingTo?.id,
        mentions: mentions,
      );
      
      // Send notifications to mentioned users
      if (mentions.isNotEmpty) {
        await _sendMentionNotifications(
          mentions: mentions,
          senderName: profile?.username ?? 'Someone',
          senderUid: user.uid,
          messageText: text,
          forumId: widget.forum.id,
          forumName: widget.forum.name,
        );
      }
      
      _messageController.clear();
      if (mounted) {
        setState(() {
          _selectedImage = null;
          _selectedGifUrl = null;
          _replyingTo = null;
          _isSending = false;
        });
      }
      await _markAsRead();
    } catch (e, stackTrace) {
      AppLogger.firebaseError('sending forum message', e, stackTrace);
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  void _showMuteSnackBar(UserProfile profile) {
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
    final day = until.toLocal();
    final formatted =
        '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}/${day.year} ${day.hour.toString().padLeft(2, '0')}:${day.minute.toString().padLeft(2, '0')}';
    return '$reason (berlaku sampai $formatted)';
  }

  Future<void> _deleteForum() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Forum'),
        content: Text('Are you sure you want to delete "${widget.forum.name}"? This action cannot be undone and will delete all messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    try {
      await _forumService.deleteForum(widget.forum.id, userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Forum deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to forums list
      }
    } catch (e, stackTrace) {
      AppLogger.firebaseError('deleting forum', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting forum: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePinMessage(ForumMessage message, bool isModerator) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Check if user is moderator (from streamed forum data)
    if (!isModerator) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only moderators can pin messages')),
        );
      }
      return;
    }
    
    try {
      if (message.isPinned) {
        await _forumService.unpinMessage(widget.forum.id, message.id);
      } else {
        await _forumService.pinMessage(widget.forum.id, message.id);
      }
    } catch (e, stackTrace) {
      AppLogger.firebaseError('${message.isPinned ? 'unpinning' : 'pinning'} message', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteMessage(ForumMessage message, bool isModerator) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Check if user can delete (moderator or message owner from streamed data)
    if (!isModerator && message.userId != userId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only delete your own messages')),
        );
      }
      return;
    }
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      try {
        await _messageService.deleteMessage(message.id, widget.forum.id);
      } catch (e, stackTrace) {
        AppLogger.firebaseError('deleting message', e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return StreamBuilder<Forum?>(
      stream: _forumStream,
      initialData: widget.forum,
      builder: (context, forumSnapshot) {
        final forum = forumSnapshot.data ?? widget.forum;
        
        // Check permissions from streamed forum data (real-time!)
        final canDelete = forum.canDelete(currentUserId);
        final isModerator = forum.moderatorIds.contains(currentUserId) || forum.createdBy == currentUserId;
        
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                // Forum cover image (small)
                if (forum.coverImage != null && forum.coverImage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: forum.coverImage!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 40,
                          height: 40,
                          color: AppColors.purpleAccent.withOpacity(0.2),
                          child: Icon(
                            Icons.forum,
                            color: AppColors.purpleAccent,
                            size: 20,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 40,
                          height: 40,
                          color: AppColors.purpleAccent.withOpacity(0.2),
                          child: Icon(
                            Icons.forum,
                            color: AppColors.purpleAccent,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Forum info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        forum.name,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${forum.memberCount} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
              // Delete forum button (creator or developer only)
              if (canDelete)
                IconButton(
                  onPressed: _deleteForum,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete Forum',
                ),
            ],
          ),
      body: Column(
        children: [
          // Pinned messages section
              PinnedMessagesSection(
                pinnedMessagesStream: _messageService.watchPinnedMessages(widget.forum.id),
                      forumId: widget.forum.id,
                isModerator: isModerator,
                onPin: (msg) => _togglePinMessage(msg, isModerator),
                onDelete: (msg) => _deleteMessage(msg, isModerator),
                      onReply: (message) => setState(() => _replyingTo = message),
          ),
          
          // Messages list
          Expanded(
            child: StreamBuilder<List<ForumMessage>>(
              stream: _messageService.watchMessages(widget.forum.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data!.where((m) => !m.isPinned).toList();
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to send a message!',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                        return ForumMessageTile(
                      message: message,
                      forumId: widget.forum.id,
                      isPinned: false,
                      onPin: () => _togglePinMessage(message, isModerator),
                      onDelete: () => _deleteMessage(message, isModerator),
                      onReply: (msg) => setState(() => _replyingTo = msg),
                    );
                  },
                );
              },
            ),
          ),
          
          StreamBuilder<UserProfile?>(
            stream: currentUserId.isNotEmpty ? _userService.watchProfile(currentUserId) : null,
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final isMuted = profile?.isMuted ?? false;
              final muteMessage = isMuted && profile != null ? _buildMuteMessage(profile) : null;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (muteMessage != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        muteMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ForumMessageInput(
                    messageController: _messageController,
                    onSendMessage: _sendMessage,
                    onPickImage: _pickImage,
                    onPickGif: _pickGif,
                    replyingTo: _replyingTo,
                    onClearReply: () => setState(() => _replyingTo = null),
                    selectedImage: _selectedImage,
                    onClearImage: () => setState(() => _selectedImage = null),
                    selectedGifUrl: _selectedGifUrl,
                    onClearGif: () => setState(() => _selectedGifUrl = null),
                    isSending: _isSending,
                    giphyService: _giphy,
                    isUserMuted: isMuted,
                    mutedMessage: muteMessage,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
      },
    );
  }
}

