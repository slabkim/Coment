import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/user_service.dart';
import 'edit_profile_screen.dart';
import 'user_list_screen.dart';
import 'reading_list_screen.dart';
import 'chat_list_screen.dart';
import 'recommendations_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final userService = UserService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppColors.black,
      body: uid == null
          ? const Center(
              child: Text(
                'Login required',
                style: TextStyle(color: AppColors.white),
              ),
            )
          : StreamBuilder<UserProfile?>(
              stream: userService.watchProfile(uid),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 24),
                    _AvatarHeader(profile: profile),
                    const SizedBox(height: 16),
                    if ((profile?.bio ?? '').isNotEmpty)
                      Text(
                        profile!.bio!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.whiteSecondary),
                      ),
                    const SizedBox(height: 24),
                    _tile(
                      context,
                      icon: Icons.message,
                      title: 'Direct Messages',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChatListScreen(),
                        ),
                      ),
                    ),
                    _tile(
                      context,
                      icon: Icons.people,
                      title: 'Followers',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const UserListScreen(title: 'Followers'),
                        ),
                      ),
                    ),
                    _tile(
                      context,
                      icon: Icons.person_add,
                      title: 'Following',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const UserListScreen(title: 'Following'),
                        ),
                      ),
                    ),
                    _tile(
                      context,
                      icon: Icons.menu_book,
                      title: 'Reading List',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReadingListScreen(),
                        ),
                      ),
                    ),
                    _tile(
                      context,
                      icon: Icons.recommend,
                      title: 'User Recommendations',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecommendationsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final UserProfile? profile;
  const _AvatarHeader({this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile?.username ?? 'Your Name';
    final handle = profile?.handle ?? profile?.email;
    final photo = profile?.photoUrl;
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFF3B2A58),
          backgroundImage: (photo != null && photo.isNotEmpty)
              ? NetworkImage(photo)
              : null,
          child: (photo == null || photo.isEmpty)
              ? Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (handle != null && handle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              handle.startsWith('@') ? handle : '@$handle',
              style: const TextStyle(color: AppColors.whiteSecondary),
            ),
          ),
      ],
    );
  }

  static String _initials(String value) {
    final parts = value.split(' ');
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : 'U';
    final second = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + second).toUpperCase();
  }
}

Widget _tile(
  BuildContext context, {
  required IconData icon,
  required String title,
  VoidCallback? onTap,
}) {
  return Column(
    children: [
      ListTile(
        leading: Icon(icon, color: AppColors.white),
        title: Text(title, style: const TextStyle(color: AppColors.white)),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.whiteSecondary,
        ),
        onTap: onTap,
      ),
      const Divider(height: 1, color: Color(0xFF22252B)),
    ],
  );
}
