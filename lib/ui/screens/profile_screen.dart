import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/user_service.dart';
import '../../data/services/follow_service.dart';
import '../../data/services/reading_status_service.dart';
import 'edit_profile_screen.dart';
import 'user_list_screen.dart';
import 'reading_list_screen.dart';
import 'chat_list_screen.dart';
import 'recommendations_screen.dart';
import 'about_screen.dart';
import 'package:provider/provider.dart';
import '../../state/theme_provider.dart';

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
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Tema',
            icon: const Icon(Icons.color_lens_outlined),
            onPressed: () => _showThemeSheet(context),
          ),
          const SizedBox(width: 8),
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
                    const SizedBox(height: 10),
                    if ((profile?.bio ?? '').isNotEmpty)
                      Text(
                        profile!.bio!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.whiteSecondary),
                      ),
                    const SizedBox(height: 18),
                    const _ProfileStats(),
                    const SizedBox(height: 10),
                    // DM entry removed (DM tersedia dari Home)
                    _tile(
                      context,
                      icon: Icons.library_books,
                      title: 'Library',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ReadingListScreen(),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const UserListScreen(title: 'Followers'),
                        ),
                      ),
                      child: _tile(
                        context,
                        icon: Icons.people,
                        title: 'Followers',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const UserListScreen(title: 'Following'),
                        ),
                      ),
                      child: _tile(
                        context,
                        icon: Icons.person_add,
                        title: 'Following',
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
                    _tile(
                      context,
                      icon: Icons.info_outline,
                      title: 'Tentang',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
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

class _ProfileStats extends StatelessWidget {
  const _ProfileStats();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final follow = FollowService();
    if (uid == null) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: follow.following(uid),
          builder: (_, s) => _StatItem(
            label: 'Following',
            value: (s.data?.length ?? 0).toString(),
          ),
        ),
        const SizedBox(width: 22),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: follow.followers(uid),
          builder: (_, s) => _StatItem(
            label: 'Followers',
            value: (s.data?.length ?? 0).toString(),
          ),
        ),
        const SizedBox(width: 22),
        StreamBuilder<List<String>>(
          stream: ReadingStatusService().watchTitlesByStatus(
            userId: uid,
            status: 'reading',
          ),
          builder: (_, s) => _StatItem(
            label: 'Reads',
            value: (s.data?.length ?? 0).toString(),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.whiteSecondary, fontSize: 12),
        ),
      ],
    );
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

void _showThemeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0E0F12),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _ThemeSheet(),
  );
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet();

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    ThemeMode current = tp.mode;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tema Aplikasi',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _themeOption(context, 'Ikuti Sistem', ThemeMode.system, current),
            _themeOption(context, 'Terang', ThemeMode.light, current),
            _themeOption(context, 'Gelap', ThemeMode.dark, current),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, String label, ThemeMode mode, ThemeMode current) {
    final tp = context.read<ThemeProvider>();
    final selected = mode == current;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? AppColors.purpleAccent : Colors.white70,
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () async {
        await tp.setMode(mode);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}
