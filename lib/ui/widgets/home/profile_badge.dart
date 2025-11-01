import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/logger.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/user_service.dart';
import '../../screens/profile_screen.dart';

/// Profile Badge for Home Screen AppBar
class ProfileBadge extends StatefulWidget {
  const ProfileBadge({super.key});

  @override
  State<ProfileBadge> createState() => _ProfileBadgeState();
}

class _ProfileBadgeState extends State<ProfileBadge> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final userService = UserService();
      final profile = await userService.fetchProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.firebaseError('loading profile for badge', e, stackTrace);
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photo = _profile?.photoUrl ?? user?.photoURL ?? '';
    
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProfileScreen())
        );
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.purpleAccent.withValues(alpha: 0.2),
        backgroundImage: (photo.isNotEmpty)
            ? NetworkImage(photo)
            : null,
        onBackgroundImageError: (photo.isNotEmpty) 
            ? (exception, stackTrace) {
                // Log image load errors but don't show to user
                AppLogger.warning('Failed to load profile image: $photo', exception, stackTrace);
              }
            : null,
        child: (photo.isEmpty)
            ? (_loading 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ))
            : null,
      ),
    );
  }
}

