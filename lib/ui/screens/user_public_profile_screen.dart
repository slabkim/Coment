import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/user_profile.dart';
import '../../data/models/user_role.dart';
import '../../data/services/user_service.dart';
import '../widgets/class_badge.dart';
import '../widgets/profile/admin_user_actions_section.dart';
import '../widgets/profile/user_profile_header.dart';
import '../widgets/profile/user_profile_action_buttons.dart';
import '../widgets/profile/favorite_manga_showcase.dart';

class UserPublicProfileScreen extends StatelessWidget {
  final String userId;
  const UserPublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final userService = UserService();
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

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header (Cover Photo, Avatar, Name, Handle, Bio)
              UserProfileHeader(profile: profile),
              
              const SizedBox(height: 24),
              
              // Action Buttons (Follow/Message)
              UserProfileActionButtons(
                profile: profile,
                userId: userId,
                isSelf: isSelf,
              ),

              StreamBuilder<UserProfile?>(
                stream: currentUid == null
                    ? null
                    : userService.watchProfile(currentUid),
                builder: (context, adminSnapshot) {
                  final viewerProfile = adminSnapshot.data;
                  final canModerate = !isSelf &&
                      currentUid != null &&
                      viewerProfile?.role == UserRole.admin;
                  if (!canModerate) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      AdminUserActionsSection(target: profile),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Class Section (Simple - no XP details for public profile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SimpleClassBadge(
                  userClass: profile.userClass,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Favorite Manga Showcase
              FavoriteMangaShowcase(userId: userId),
            ],
          );
        },
      ),
    );
  }
}
