import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/auth_helper.dart';
import '../../core/logger.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/chat_history_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/giphy_service.dart';
import '../../data/services/user_service.dart';
import '../widgets/chat/chat_helpers.dart';
import '../widgets/chat/chat_message_input.dart';
import '../widgets/chat/chat_message_tile.dart';
import '../widgets/chat/login_required_widget.dart';
import '../widgets/class_badge.dart';
import 'user_public_profile_screen.dart';

class ChatScreen extends StatefulWidget {
  final String peerUserId;
  final String peerDisplayName;
  final String? peerPhotoUrl;
  const ChatScreen({
    super.key,
    required this.peerUserId,
    required this.peerDisplayName,
    this.peerPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageC = TextEditingController();
  final _scrollC = ScrollController();
  final _giphy = GiphyService();
  final _chat = ChatService();
  String? _chatId;
  final _history = ChatHistoryService();
  final _userService = UserService();
  final _imagePicker = ImagePicker();
  String? _selfName;
  File? _selectedImage;
  String? _selectedGifUrl;
  bool _isUploadingImage = false; // Only for image upload, not for text/GIF messages
  int? _lastIncomingMarkedAt;

  @override
  void dispose() {
    _messageC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSelfProfile();
    // Update lastSeen when entering chat
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userService.updateLastSeen(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: StreamBuilder<UserProfile?>(
          stream: _userService.watchProfile(widget.peerUserId),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final name = profile?.username ?? widget.peerDisplayName;
            final photo = profile?.photoUrl ?? widget.peerPhotoUrl;
            // Use joinedAt as fallback if lastSeen not available
            final lastSeen = profile?.lastSeen ?? profile?.joinedAt;
            final onlineStatus = ChatHelpers.getOnlineStatus(lastSeen);
            
            return GestureDetector(
              onTap: () => _navigateToProfile(widget.peerUserId),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    backgroundImage: (photo != null && photo.isNotEmpty)
                        ? NetworkImage(photo)
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? Text(
                            ChatHelpers.initials(name),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (profile?.userClass != null) ...[
                              const SizedBox(width: 6),
                              CompactClassBadge(
                                userClass: profile!.userClass,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          onlineStatus,
                          style: TextStyle(
                            fontSize: 12,
                            color: onlineStatus == 'Online'
                                ? Colors.greenAccent
                                : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: uid == null
                ? const LoginRequiredWidget()
                : FutureBuilder<String>(
                    future: _initChat(uid),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final cid = snap.data!;
                      return StreamBuilder<int?>(
                        stream: _history.watchLastRead(cid, widget.peerUserId),
                        builder: (context, readSnap) {
                          // Handle error in watchLastRead stream - just use 0 as default
                          final peerLastRead = readSnap.hasError ? 0 : (readSnap.data ?? 0);
                          return StreamBuilder<List<ChatMessage>>(
                            stream: _chat.watchMessages(cid),
                            builder: (context, s2) {
                              // Handle error state
                              if (s2.hasError) {
                                final error = s2.error;
                                
                                // Log error for debugging
                                if (error != null) {
                                  AppLogger.firebaseError('Loading chat messages', error, StackTrace.current);
                                }
                                
                                // Show generic error message
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.error,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Error Loading Messages',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Unable to load messages. Please try again.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              // Handle loading state
                              if (s2.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              // Handle empty state
                              if (!s2.hasData) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.chat_bubble_outline,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No Messages',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Start a conversation by sending a message.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              final msgs = s2.data ?? const [];
                              _markIncomingAsRead(cid, uid, msgs);
                              return ListView.builder(
                                controller: _scrollC,
                                reverse: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                itemCount: msgs.length,
                                itemBuilder: (context, i) {
                                  final m = msgs[i];
                                  final isMe = m.senderId == uid;
                                  final isRead =
                                      isMe &&
                                      (m.createdAt.millisecondsSinceEpoch <=
                                          peerLastRead);
                                  return ChatMessageTile(
                                    message: m,
                                    isMe: isMe,
                                    isRead: isRead,
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          
          // Message input
          ChatMessageInput(
            messageController: _messageC,
            onSendMessage: _send,
            onPickImage: _pickImage,
            onPickGif: (url) {
              setState(() {
                _selectedGifUrl = url;
                _selectedImage = null; // Clear image if GIF is selected
              });
            },
            selectedImage: _selectedImage,
            onClearImage: () => setState(() => _selectedImage = null),
            selectedGifUrl: _selectedGifUrl,
            onClearGif: () => setState(() => _selectedGifUrl = null),
            isUploadingImage: _isUploadingImage,
            giphyService: _giphy,
          ),
        ],
      ),
    );
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
      AppLogger.error('picking image', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<String?> _uploadMessageImage(String messageId) async {
    if (_selectedImage == null) return null;
    
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(_chatId!)
          .child('$messageId.jpg');
      
      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();
      
      return downloadUrl;
    } catch (e, stackTrace) {
      AppLogger.firebaseError('uploading chat image', e, stackTrace);
      return null;
    }
  }

  Future<void> _send() async {
    final text = _messageC.text.trim();
    if (text.isEmpty && _selectedImage == null && _selectedGifUrl == null) return;

    // Prevent spam clicking only for image upload
    if (_isUploadingImage) return;

    // Quick check: if already logged in, skip dialog
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Only show dialog if not logged in
      final success = await AuthHelper.requireAuthWithDialog(
        context,
        'send a message',
      );
      if (!success) return;
      // Re-check uid after potential login
      final newUid = FirebaseAuth.instance.currentUser?.uid;
      if (newUid == null || _chatId == null) return;
    }
    
    if (_chatId == null) return;
    
    // Get final uid (guaranteed to be non-null at this point)
    final finalUid = FirebaseAuth.instance.currentUser?.uid ?? uid;
    if (finalUid == null) return; // Safety check
    
    // Handle image upload first (this takes time, so show loading ONLY for image upload)
    String? imageUrl;
    final isImageUpload = _selectedImage != null;
    final isGifUpload = _selectedGifUrl != null;
    
    // Clear text input immediately (for all message types)
    final messageText = text;
    _messageC.clear();
    
    final senderName =
        _selfName ??
        FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@').first;
    
    // Handle image upload with loading indicator
    if (isImageUpload) {
      setState(() => _isUploadingImage = true);
      try {
        final tempId = DateTime.now().millisecondsSinceEpoch.toString();
        imageUrl = await _uploadMessageImage(tempId);
        if (imageUrl == null) {
          // Upload failed
          if (mounted) {
            setState(() => _isUploadingImage = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error uploading image')),
            );
          }
          return;
        }
        
        // Send message after upload
        try {
          await _chat.sendImage(
            chatId: _chatId!,
            senderId: finalUid,
            imageUrl: imageUrl,
            senderName: senderName,
          );
          // Clear preview and loading after message sent successfully
          if (mounted) {
            setState(() {
              _selectedImage = null;
              _isUploadingImage = false;
            });
          }
        } catch (e) {
          // Send failed
          if (mounted) {
            setState(() => _isUploadingImage = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error sending message: $e')),
            );
          }
          return;
        }
      } catch (e, stackTrace) {
        AppLogger.error('uploading image', e, stackTrace);
        if (mounted) {
          setState(() => _isUploadingImage = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
        }
        return;
      }
    } else if (isGifUpload) {
      // For GIF: send immediately (no upload needed), then clear preview
      final gifUrl = _selectedGifUrl;
      try {
        await _chat.sendImage(
          chatId: _chatId!,
          senderId: finalUid,
          imageUrl: gifUrl!,
          senderName: senderName,
        );
        // Clear preview after message sent successfully
        if (mounted) {
          setState(() => _selectedGifUrl = null);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending message: $e')),
          );
        }
        return;
      }
    } else if (messageText.isNotEmpty) {
      // For text: send immediately (no loading indicator)
      try {
        await _chat.sendText(
          chatId: _chatId!,
          senderId: finalUid,
          text: messageText,
          senderName: senderName,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending message: $e')),
          );
        }
        return;
      }
    }
    
    // Scroll to bottom immediately (message will appear via StreamBuilder)
    _scrollC.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }


  Future<String> _initChat(String uid) async {
    if (_chatId != null) return _chatId!;
    final peer = widget.peerUserId;
    final id = await _chat.ensureChat(uid, peer);
    _chatId = id;
    _lastIncomingMarkedAt = null;
    return id;
  }

  Future<void> _loadSelfProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await _userService.fetchProfile(user.uid);
    if (!mounted) return;
    setState(() {
      _selfName =
          profile?.username ?? user.displayName ?? user.email?.split('@').first;
    });
  }

  void _markIncomingAsRead(String chatId, String uid, List<ChatMessage> msgs) {
    // Only mark read when a newer incoming message exists to avoid write loops.
    final latestIncomingTs = msgs
        .where((m) => m.senderId != uid)
        .map((m) => m.createdAt.millisecondsSinceEpoch)
        .fold<int?>(null, (prev, ts) => prev == null ? ts : (ts > prev ? ts : prev));

    if (latestIncomingTs != null &&
        (_lastIncomingMarkedAt == null || latestIncomingTs > _lastIncomingMarkedAt!)) {
      _lastIncomingMarkedAt = latestIncomingTs;
      _history.markReadNow(chatId, uid);
    }
  }
  
  void _navigateToProfile(String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserPublicProfileScreen(userId: userId),
      ),
    );
  }
}
