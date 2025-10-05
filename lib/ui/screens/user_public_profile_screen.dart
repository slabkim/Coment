import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/follow_service.dart';
import '../../data/services/user_service.dart';
import 'chat_screen.dart';

class UserPublicProfileScreen extends StatelessWidget {
  final String userId;
  const UserPublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final userService = UserService();
    final followService = FollowService();
    final isSelf = currentUid == userId;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: const Text('Profile'),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: userService.watchProfile(userId),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (profile == null) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: Text(
                'User not found',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            );
          }
          final name =
              profile.username ?? profile.handle ?? profile.email ?? 'User';
          final handle = profile.handle ?? profile.email ?? '';
          final photo = profile.photoUrl;
          final bio = profile.bio ?? '';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: (photo != null && photo.isNotEmpty)
                      ? NetworkImage(photo)
                      : null,
                  child: (photo == null || photo.isEmpty)
                      ? Text(
                          _initials(name),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (handle.isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      handle.startsWith('@') ? handle : '@$handle',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              if (bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 24),
              if (!isSelf)
                StreamBuilder<bool>(
                  stream: currentUid == null
                      ? const Stream<bool>.empty()
                      : followService.isFollowing(currentUid, userId),
                  builder: (context, followSnap) {
                    final isFollowing = followSnap.data ?? false;
                    return Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: currentUid == null
                                ? () => _requireLogin(context)
                                : () => followService.toggleFollow(
                                    followerId: currentUid,
                                    followingId: userId,
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: isFollowing
                                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                                  : Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              isFollowing ? 'Following' : 'Follow',
                              style: TextStyle(
                                color: isFollowing
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: currentUid == null
                                ? () => _requireLogin(context)
                                : () {
                                    final displayName =
                                        profile.username ??
                                        profile.handle ??
                                        'User';
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          peerUserId: userId,
                                          peerDisplayName: displayName,
                                          peerPhotoUrl: photo,
                                        ),
                                      ),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.purpleAccent,
                              ),
                              foregroundColor: AppColors.purpleAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Message'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              if (isSelf)
                const Center(
                  child: Text(
                    'This is you!',
                    style: TextStyle(color: AppColors.whiteSecondary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _requireLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to use this feature')),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(' ');
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : 'U';
    final second = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + second).toUpperCase();
  }
}
