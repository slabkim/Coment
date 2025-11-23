import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/user_profile.dart';
import '../../data/services/user_service.dart';
import '../widgets/class_badge.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_login_required.dart';
import '../widgets/profile/favorite_manga_showcase.dart';
import '../widgets/profile/profile_helpers.dart';
import 'admin_dashboard_screen.dart';

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
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            actions: uid != null ? [
              IconButton(
                tooltip: 'Settings',
                icon: Icon(
                  Icons.settings_outlined,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black87 // Dark icon for light mode
                      : Colors.white, // White icon for dark mode
                ),
                onPressed: () => ProfileHelpers.showSettingsSheet(context),
              ),
              const SizedBox(width: 8),
            ] : null,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: uid == null
              ? const ProfileLoginRequired()
              : StreamBuilder<UserProfile?>(
                  stream: userService.watchProfile(uid),
                  builder: (context, snapshot) {
                    final profile = snapshot.data;
                    return CustomScrollView(
                      slivers: [
                        // Cover Photo Header
                        SliverToBoxAdapter(
                          child: ProfileHeader(profile: profile, uid: uid),
                        ),
                        
                        if (profile?.canModerate ?? false)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Card(
                                child: ListTile(
                                  leading: const Icon(Icons.shield_outlined),
                                  title: const Text('Open Admin Dashboard'),
                                  subtitle: const Text('Manage users, rooms, and reports'),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const AdminDashboardScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        
                        // XP & Class Section
                        if (profile != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: LargeClassBadge(
                                userClass: profile.userClass,
                                xp: profile.xp,
                              ),
                            ),
                          ),
                        
                        // Favorite Manga Showcase
                        SliverToBoxAdapter(
                          child: FavoriteMangaShowcase(userId: uid),
                        ),
                        
                        const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
