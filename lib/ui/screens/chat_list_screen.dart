import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants.dart';
import '../../data/services/chat_service.dart';
import '../../data/models/chat.dart';
import 'chat_screen.dart';
import '../../data/services/chat_history_service.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final chatService = ChatService();
    final history = ChatHistoryService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Messages'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.black,
      body: uid == null
          ? const Center(child: Text('Login required', style: TextStyle(color: AppColors.white)))
          : StreamBuilder<List<Chat>>(
              stream: chatService.watchUserChats(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final chats = snapshot.data ?? const [];
                if (chats.isEmpty) {
                  return const Center(
                    child: Text('No chats yet', style: TextStyle(color: AppColors.whiteSecondary)),
                  );
                }
                return ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF22252B)),
                  itemBuilder: (context, i) {
                    final c = chats[i];
                    final otherId = c.participants.firstWhere((p) => p != uid, orElse: () => uid);
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        otherId,
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        c.lastMessage ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.whiteSecondary),
                      ),
                      trailing: StreamBuilder<int?>(
                        stream: history.watchLastRead(c.id, uid),
                        builder: (context, s3) {
                          final lastRead = s3.data ?? 0;
                          final lastMsg = c.lastMessageTime?.millisecondsSinceEpoch ?? 0;
                          final unread = lastMsg > lastRead;
                          return unread
                              ? const CircleAvatar(radius: 6, backgroundColor: Colors.red)
                              : const SizedBox(width: 0, height: 0);
                        },
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(peerUserId: otherId, peerDisplayName: otherId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}


