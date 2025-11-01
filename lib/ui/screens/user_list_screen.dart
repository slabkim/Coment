import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_profile.dart';
import '../../data/services/follow_service.dart';
import '../../data/services/user_service.dart';
import 'user_public_profile_screen.dart';

class UserListScreen extends StatelessWidget {
  final String title;
  const UserListScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final svc = FollowService();
    final userService = UserService();
    final isFollowers = title.toLowerCase().contains('follower');
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: uid == null
          ? Center(
              child: Text(
                'Login required',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: isFollowers ? svc.followers(uid) : svc.following(uid),
              builder: (context, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'No users',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: Theme.of(context).dividerTheme.color),
                  itemBuilder: (context, i) {
                    final m = items[i];
                    final otherId = isFollowers
                        ? (m['followerId'] as String)
                        : (m['followingId'] as String);
                    final isSelf = otherId == uid;
                    return StreamBuilder<UserProfile?>(
                      stream: userService.watchProfile(otherId),
                      builder: (context, userSnap) {
                        final profile = userSnap.data;
                        final displayName =
                            profile?.username ?? profile?.handle ?? otherId;
                        final photo = profile?.photoUrl;
                        final handle = profile?.handle;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            backgroundImage: (photo != null && photo.isNotEmpty)
                                ? NetworkImage(photo)
                                : null,
                            child: (photo == null || photo.isEmpty)
                                ? Text(
                                    _initials(displayName),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            displayName,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          ),
                          subtitle: Text(
                            handle == null || handle.isEmpty
                                ? 'Tap to view profile'
                                : (handle.startsWith('@')
                                      ? handle
                                      : '@$handle'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: isSelf
                              ? null
                              : StreamBuilder<bool>(
                                  stream: svc.isFollowing(uid, otherId),
                                  builder: (context, followSnap) {
                                    final isFollowing =
                                        followSnap.data ?? false;
                                    return FilledButton(
                                      onPressed: () => svc.toggleFollow(
                                        followerId: uid,
                                        followingId: otherId,
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isFollowing
                                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                                            : Theme.of(context).colorScheme.primary,
                                      ),
                                      child: Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: TextStyle(
                                          color: isFollowing
                                              ? Theme.of(context).colorScheme.onSurface
                                              : Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserPublicProfileScreen(userId: otherId),
                              ),
                            );
                          },
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

String _initials(String name) {
  final parts = name.trim().split(' ');
  final first = parts.isNotEmpty && parts.first.isNotEmpty
      ? parts.first[0]
      : 'U';
  final second = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + second).toUpperCase();
}
