import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/chat.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/chat_history_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/user_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final chatService = ChatService();
    final history = ChatHistoryService();
    final userService = UserService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Messages'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.black,
      body: uid == null
          ? const Center(
              child: Text(
                'Login required',
                style: TextStyle(color: AppColors.white),
              ),
            )
          : StreamBuilder<List<Chat>>(
              stream: chatService.watchUserChats(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats = snapshot.data ?? const [];
                if (chats.isEmpty) {
                  return const Center(
                    child: Text(
                      'No chats yet',
                      style: TextStyle(color: AppColors.whiteSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFF22252B)),
                  itemBuilder: (context, i) {
                    final c = chats[i];
                    final otherId = c.participants.firstWhere(
                      (p) => p != uid,
                      orElse: () => uid,
                    );
                    return StreamBuilder<UserProfile?>(
                      stream: userService.watchProfile(otherId),
                      builder: (context, userSnap) {
                        final profile = userSnap.data;
                        final displayName =
                            profile?.username ?? profile?.handle ?? otherId;
                        final photo = profile?.photoUrl;
                        final subtitle = c.lastMessage ?? 'Say hello!';
                        final timeLabel = _formatTime(c.lastMessageTime);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.purpleAccent.withValues(
                              alpha: 0.2,
                            ),
                            backgroundImage: (photo != null && photo.isNotEmpty)
                                ? NetworkImage(photo)
                                : null,
                            child: (photo == null || photo.isEmpty)
                                ? Text(
                                    _initials(displayName),
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                          title: Text(
                            displayName,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.whiteSecondary,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (timeLabel != null)
                                Text(
                                  timeLabel,
                                  style: const TextStyle(
                                    color: AppColors.whiteSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              StreamBuilder<int?>(
                                stream: history.watchLastRead(c.id, uid),
                                builder: (context, s3) {
                                  final lastRead = s3.data ?? 0;
                                  final lastMsg =
                                      c
                                          .lastMessageTime
                                          ?.millisecondsSinceEpoch ??
                                      0;
                                  final unread = lastMsg > lastRead;
                                  return unread
                                      ? const CircleAvatar(
                                          radius: 6,
                                          backgroundColor: Colors.red,
                                        )
                                      : const SizedBox(width: 0, height: 0);
                                },
                              ),
                            ],
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                peerUserId: otherId,
                                peerDisplayName: displayName,
                                peerPhotoUrl: photo,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

String? _formatTime(DateTime? time) {
  if (time == null) return null;
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}w';
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  final first = parts.isNotEmpty && parts.first.isNotEmpty
      ? parts.first[0]
      : 'U';
  final second = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + second).toUpperCase();
}
