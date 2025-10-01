import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/follow_service.dart';

class UserListScreen extends StatelessWidget {
  final String title;
  const UserListScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final svc = FollowService();
    final isFollowers = title.toLowerCase().contains('follower');
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      backgroundColor: AppColors.black,
      body: uid == null
          ? const Center(child: Text('Login required', style: TextStyle(color: AppColors.white)))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: isFollowers ? svc.followers(uid) : svc.following(uid),
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No users', style: TextStyle(color: AppColors.whiteSecondary)),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF22252B)),
                  itemBuilder: (context, i) {
                    final m = items[i];
                    final otherId = isFollowers ? (m['followerId'] as String) : (m['followingId'] as String);
                    final isSelf = otherId == uid;
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(otherId, style: const TextStyle(color: AppColors.white)),
                      subtitle: const Text('Tap to open profile', style: TextStyle(color: AppColors.whiteSecondary)),
                      trailing: isSelf
                          ? null
                          : FilledButton(
                              onPressed: () => svc.toggleFollow(followerId: uid, followingId: otherId),
                              style: FilledButton.styleFrom(backgroundColor: AppColors.purpleAccent),
                              child: const Text('Follow/Unfollow'),
                            ),
                    );
                  },
                );
              },
            ),
    );
  }
}


