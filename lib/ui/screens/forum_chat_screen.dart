import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants.dart';
import '../../data/models/forum.dart';
import '../../data/models/forum_message.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/forum_service.dart';
import '../../data/services/forum_message_service.dart';
import '../../data/services/forum_member_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/giphy_service.dart';
import '../widgets/class_badge.dart';
import 'user_public_profile_screen.dart';

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
  
  // Shared cache for username -> userId mapping (static to share with _MessageTileState)
  static final Map<String, String?> _usernameCache = {};
  static final Set<String> _fetchingUsernames = {};
  final _imagePicker = ImagePicker();
  final _giphy = GiphyService();
  
  bool _showPinned = true;
  Stream<Forum?>? _forumStream;
  File? _selectedImage;
  String? _selectedGifUrl;
  ForumMessage? _replyingTo;
  List<String> _mentions = [];
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickGif() async {
    final url = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white // White for light mode
          : const Color(0xFF0E0F12), // Dark for dark mode
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      builder: (_) => _GifPicker(giphy: _giphy),
    );
    
    if (url != null && url.isNotEmpty) {
      setState(() {
        _selectedGifUrl = url;
        _selectedImage = null; // Clear image if GIF is selected
      });
    }
  }

  Future<String?> _uploadMessageImage(String messageId) async {
    if (_selectedImage == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('forum_message_images')
          .child('${widget.forum.id}')
          .child('$messageId.jpg');
      
      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading message image: $e');
      return null;
    }
  }

  List<String> _extractMentions(String text) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }
  
  /// Find user ID by username and validate they're a forum member
  Future<String?> _getUserIdByUsername(String username, String forumId) async {
    // Create cache key with forumId to ensure forum-specific validation
    final cacheKey = '${forumId}_$username';
    
    // Check cache first
    if (_usernameCache.containsKey(cacheKey)) {
      debugPrint('💾 Cache hit for: $username in forum $forumId (${_usernameCache[cacheKey]})');
      return _usernameCache[cacheKey];
    }
    
    // If already fetching, wait a bit and check cache again
    if (_fetchingUsernames.contains(cacheKey)) {
      debugPrint('⏳ Already fetching: $username, waiting...');
      await Future.delayed(const Duration(milliseconds: 100));
      return _usernameCache[cacheKey];
    }
    
    // Mark as fetching
    _fetchingUsernames.add(cacheKey);
    
    try {
      debugPrint('🔍 Querying for username: $username in forum $forumId');
      
      // Try querying by 'handle' field first (most common)
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('handle', isEqualTo: username)
          .limit(1)
          .get();
      
      // If not found, try 'username' field
      if (querySnapshot.docs.isEmpty) {
        debugPrint('   Trying username field...');
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
      }
      
      debugPrint('📊 Query result: ${querySnapshot.docs.length} docs found');
      
      String? userId;
      if (querySnapshot.docs.isNotEmpty) {
        userId = querySnapshot.docs.first.id;
        final userData = querySnapshot.docs.first.data();
        debugPrint('✅ Found user: $username (ID: $userId)');
        debugPrint('   Handle: ${userData['handle']}, Username: ${userData['username']}');
        
        // ✅ VALIDATION: Check if user is a member of this forum
        final memberDocId = '${forumId}_$userId';
        final memberDoc = await FirebaseFirestore.instance
            .collection('forum_members')
            .doc(memberDocId)
            .get();
        
        if (!memberDoc.exists) {
          debugPrint('❌ User $username is NOT a member of forum $forumId');
          userId = null; // Not a member, treat as invalid
        } else {
          debugPrint('✅ User $username is a member of forum $forumId');
        }
      } else {
        debugPrint('❌ Username not found: $username');
      }
      
      // Cache the result (even if null)
      _usernameCache[cacheKey] = userId;
      return userId;
    } catch (e) {
      debugPrint('⚠️ Error finding user by username: $e');
      _usernameCache[cacheKey] = null; // Cache the failure too
      return null;
    } finally {
      // Remove from fetching set
      _fetchingUsernames.remove(cacheKey);
    }
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
        debugPrint('📬 Sending mention notification to @$username');
        
        // Find user ID by username (validate they're in the forum)
        final userId = await _getUserIdByUsername(username, forumId);
        
        if (userId == null) {
          debugPrint('⚠️ Cannot send notification: @$username not found or not a member');
          continue;
        }
        
        // Don't notify yourself
        if (userId == senderUid) {
          debugPrint('⚠️ Skipping self-mention notification');
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
        
        debugPrint('✅ Mention notification sent to @$username (UID: $userId)');
      }
    } catch (e) {
      debugPrint('⚠️ Error sending mention notifications: $e');
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
          _mentions = [];
          _isSending = false;
        });
      }
      await _markAsRead();
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
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
    } catch (e) {
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
    } catch (e) {
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
      } catch (e) {
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
          StreamBuilder<List<ForumMessage>>(
            stream: _messageService.watchPinnedMessages(widget.forum.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final pinnedMessages = snapshot.data!;
              
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() => _showPinned = !_showPinned);
                    },
                    child: Container(
                      color: AppColors.purpleAccent.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.push_pin,
                            size: 16,
                            color: AppColors.purpleAccent,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pinnedMessages.length} pinned message${pinnedMessages.length > 1 ? "s" : ""}',
                            style: TextStyle(
                              color: AppColors.purpleAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _showPinned ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.purpleAccent,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showPinned)
                    ...pinnedMessages.map((msg) => _MessageTile(
                      message: msg,
                      forumId: widget.forum.id,
                      isPinned: true,
                      onPin: () => _togglePinMessage(msg, isModerator),
                      onDelete: () => _deleteMessage(msg, isModerator),
                      onReply: (message) => setState(() => _replyingTo = message),
                    )),
                ],
              );
            },
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
                    return _MessageTile(
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
          
          // Message input (always show if logged in)
          _buildMessageInput(),
        ],
      ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview
          if (_replyingTo != null)
            _buildReplyPreview(),
          
          // Image preview
          if (_selectedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.purpleAccent),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ],
              ),
            ),
          
          // GIF preview
          if (_selectedGifUrl != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.purpleAccent),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _selectedGifUrl!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        width: double.infinity,
                        height: 120,
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        child: const Icon(Icons.error, size: 32),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                      onPressed: () => setState(() => _selectedGifUrl = null),
                    ),
                  ),
                ],
              ),
            ),
          
          // Input row
          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: Icon(
                  Icons.image,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: 'Add Image',
              ),
              IconButton(
                onPressed: _pickGif,
                icon: Icon(
                  Icons.gif_box,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: 'Add GIF',
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.send,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();
    
    // Get preview text
    String previewText = '';
    if (_replyingTo!.text.isNotEmpty) {
      previewText = _replyingTo!.text.length > 50 
          ? '${_replyingTo!.text.substring(0, 50)}...' 
          : _replyingTo!.text;
    } else if (_replyingTo!.imageUrl != null) {
      previewText = '📷 Photo';
    } else if (_replyingTo!.gifUrl != null) {
      previewText = '🎬 GIF';
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.purpleAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: AppColors.purpleAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyingTo!.userName}',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF3B82F6) // Blue for light mode
                        : AppColors.purpleAccent, // Purple for dark mode
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (previewText.isNotEmpty)
                  Text(
                    previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
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
    );
  }
}

class _MessageTile extends StatefulWidget {
  final ForumMessage message;
  final String forumId;
  final bool isPinned;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final Function(ForumMessage) onReply;

  const _MessageTile({
    required this.message,
    required this.forumId,
    required this.isPinned,
    required this.onPin,
    required this.onDelete,
    required this.onReply,
  });

  @override
  State<_MessageTile> createState() => _MessageTileState();
}

class _MessageTileState extends State<_MessageTile> {
  final _messageService = ForumMessageService();

  Future<void> _toggleReaction(String emoji) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    try {
      await _messageService.toggleReaction(widget.message.id, userId, emoji);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding reaction: $e')),
        );
      }
    }
  }

  void _showReactionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final emojis = ['👍', '❤️', '😂', '😮', '😢', '🔥', '👏', '🎉'];
        
        return SafeArea(
          child: Padding(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnMessage = widget.message.userId == currentUserId;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onLongPress: () => _showOptions(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.message.userAvatar != null
                  ? CachedNetworkImageProvider(widget.message.userAvatar!)
                  : null,
              onBackgroundImageError: widget.message.userAvatar != null
                  ? (exception, stackTrace) {
                      debugPrint('Avatar load error: $exception');
                    }
                  : null,
              child: widget.message.userAvatar == null
                  ? Text(
                      widget.message.userName.isNotEmpty ? widget.message.userName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 16),
                    )
                  : null,
            ),
            
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

  Widget _buildUserInfo() {
    return StreamBuilder<UserProfile?>(
      stream: UserService().watchProfile(widget.message.userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final isDev = profile?.isDeveloper ?? false;
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
            
            // Dev badge
            if (isDev) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            
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

  // Reply indicator shown in sent messages
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
                            ? const Color(0xFF3B82F6) // Blue for light mode
                            : AppColors.purpleAccent.withOpacity(0.8), // Purple for dark mode
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
    } catch (e) {
      debugPrint('Error fetching reply message: $e');
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
            future: _getUserIdByUsername(username, widget.forumId),
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
                            ? Colors.black87 // Black for light mode
                            : Colors.white) // White for dark mode
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

  Future<String?> _getUserIdByUsername(String username, String forumId) async {
    // Create cache key with forumId to ensure forum-specific validation
    final cacheKey = '${forumId}_$username';
    
    // Check cache first (use shared static cache from _ForumChatScreenState)
    if (_ForumChatScreenState._usernameCache.containsKey(cacheKey)) {
      debugPrint('💾 Cache hit for: $username in forum $forumId (${_ForumChatScreenState._usernameCache[cacheKey]})');
      return _ForumChatScreenState._usernameCache[cacheKey];
    }
    
    // If already fetching, wait a bit and check cache again
    if (_ForumChatScreenState._fetchingUsernames.contains(cacheKey)) {
      debugPrint('⏳ Already fetching: $username, waiting...');
      await Future.delayed(const Duration(milliseconds: 100));
      return _ForumChatScreenState._usernameCache[cacheKey];
    }
    
    // Mark as fetching
    _ForumChatScreenState._fetchingUsernames.add(cacheKey);
    
    try {
      debugPrint('🔍 Querying for username: $username in forum $forumId');
      
      // Try querying by 'handle' field first (most common)
      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('handle', isEqualTo: username)
          .limit(1)
          .get();
      
      // If not found, try 'username' field
      if (querySnapshot.docs.isEmpty) {
        debugPrint('   Trying username field...');
        querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
      }
      
      debugPrint('📊 Query result: ${querySnapshot.docs.length} docs found');
      
      String? userId;
      if (querySnapshot.docs.isNotEmpty) {
        userId = querySnapshot.docs.first.id;
        final userData = querySnapshot.docs.first.data();
        debugPrint('✅ Found user: $username (ID: $userId)');
        debugPrint('   Handle: ${userData['handle']}, Username: ${userData['username']}');
        
        // ✅ VALIDATION: Check if user is a member of this forum
        final memberDocId = '${forumId}_$userId';
        final memberDoc = await FirebaseFirestore.instance
            .collection('forum_members')
            .doc(memberDocId)
            .get();
        
        if (!memberDoc.exists) {
          debugPrint('❌ User $username is NOT a member of forum $forumId');
          userId = null; // Not a member, treat as invalid
        } else {
          debugPrint('✅ User $username is a member of forum $forumId');
        }
      } else {
        debugPrint('❌ Username not found: $username');
      }
      
      // Cache the result (even if null) - use shared static cache
      _ForumChatScreenState._usernameCache[cacheKey] = userId;
      return userId;
    } catch (e) {
      debugPrint('⚠️ Error finding user by username: $e');
      _ForumChatScreenState._usernameCache[cacheKey] = null; // Cache the failure too
      return null;
    } finally {
      // Remove from fetching set
      _ForumChatScreenState._fetchingUsernames.remove(cacheKey);
    }
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
      builder: (context) {
        return SafeArea(
          child: Column(
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
              // Pin option (will check moderator permission on tap)
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
              // Delete option (will check permission on tap)
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

// GIF Picker Widget (Modal Bottom Sheet)
class _GifPicker extends StatefulWidget {
  final GiphyService giphy;
  const _GifPicker({required this.giphy});

  @override
  State<_GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends State<_GifPicker> {
  final _q = TextEditingController(text: 'anime');
  List<String> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Auto-search with default query on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search();
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black87 // Black for light mode
                          : Colors.white, // White for dark mode
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search GIFs',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[200] // Light grey for light mode
                          : const Color(0xFF121316), // Dark for dark mode
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF3B82F6) // Blue for light mode
                        : AppColors.purpleAccent, // Purple for dark mode
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gif_box_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No GIFs found',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () => Navigator.pop(context, _results[i]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _results[i],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFF121316),
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final res = await widget.giphy.searchGifs(
        query: _q.text.trim().isEmpty ? 'anime' : _q.text.trim(),
      );
      setState(() => _results = res);
    } catch (e) {
      debugPrint('Error searching GIFs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading GIFs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

