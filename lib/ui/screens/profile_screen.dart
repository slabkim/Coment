import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants.dart';
import '../../core/auth_helper.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/user_service.dart';
import '../../data/services/follow_service.dart';
import '../../data/services/reading_status_service.dart';
import 'edit_profile_screen.dart';
import 'user_list_screen.dart';
import 'reading_list_screen.dart';
import 'recommendations_screen.dart';
import 'about_screen.dart';
import 'package:provider/provider.dart';
import '../../state/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final uid = user?.uid;

        // Debug log
        debugPrint('ProfileScreen - Auth state changed: ${user?.uid}');
        debugPrint('ProfileScreen - Current user: $user');

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            actions: uid != null
                ? [
                    IconButton(
                      tooltip: 'Edit profile',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Tema',
                      icon: const Icon(Icons.color_lens_outlined),
                      onPressed: () => _showThemeSheet(context),
                    ),
                    IconButton(
                      tooltip: 'Logout',
                      icon: const Icon(Icons.logout),
                      onPressed: () => _showLogoutDialog(context),
                    ),
                    const SizedBox(width: 8),
                  ]
                : null,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: uid == null
              ? _LoginRequiredWidget()
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
                            style: const TextStyle(
                              color: AppColors.whiteSecondary,
                            ),
                          ),
                        const SizedBox(height: 18),
                        const _ProfileStats(),
                        const SizedBox(height: 10),
                        // Reading List - main access point
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
      },
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (handle != null && handle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              handle.startsWith('@') ? handle : '@$handle',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
          builder: (_, s) => GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UserListScreen(title: 'Following'),
              ),
            ),
            child: _StatItem(
              label: 'Following',
              value: (s.data?.length ?? 0).toString(),
            ),
          ),
        ),
        const SizedBox(width: 22),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: follow.followers(uid),
          builder: (_, s) => GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UserListScreen(title: 'Followers'),
              ),
            ),
            child: _StatItem(
              label: 'Followers',
              value: (s.data?.length ?? 0).toString(),
            ),
          ),
        ),
        const SizedBox(width: 22),
        StreamBuilder<List<String>>(
          stream: ReadingStatusService().watchAllReadingTitles(uid),
          builder: (_, s) => GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReadingListScreen()),
            ),
            child: _StatItem(
              label: 'Reads',
              value: (s.data?.length ?? 0).toString(),
            ),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
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
        leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
        title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
      Divider(height: 1, color: Theme.of(context).dividerTheme.color),
    ],
  );
}

void _showThemeSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _ThemeSheet(),
  );
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0E0F12),
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Apakah Anda yakin ingin logout?',
          style: TextStyle(color: AppColors.whiteSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.whiteSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _logout(context);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

Future<void> _logout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    if (context.mounted) {
      // Navigate to login screen or show login required message
      Navigator.of(context).pushReplacementNamed('/login');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout gagal: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
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
            Text(
              'Tema Aplikasi',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
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

  Widget _themeOption(
    BuildContext context,
    String label,
    ThemeMode mode,
    ThemeMode current,
  ) {
    final tp = context.read<ThemeProvider>();
    final selected = mode == current;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () async {
        await tp.setMode(mode);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

class _LoginRequiredWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Login Required',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please login to access your profile and personal features',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final success = await AuthHelper.requireAuth(context);
                if (success && context.mounted) {
                  // Refresh the screen to show profile
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Login Now'),
            ),
          ],
        ),
      ),
    );
  }
}
