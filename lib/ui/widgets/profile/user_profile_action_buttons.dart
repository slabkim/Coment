import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/services/follow_service.dart';
import '../../screens/chat_screen.dart';

/// Action Buttons for Public User Profile (Follow/Message)
class UserProfileActionButtons extends StatelessWidget {
  final UserProfile profile;
  final String userId;
  final bool isSelf;
  
  const UserProfileActionButtons({
    super.key,
    required this.profile,
    required this.userId,
    required this.isSelf,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final followService = FollowService();
    final photo = profile.photoUrl;
    
    if (isSelf) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'This is you!',
            style: TextStyle(color: AppColors.whiteSecondary),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<bool>(
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
                    backgroundColor: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF3B82F6) // Blue for light mode
                        : AppColors.purpleAccent, // Purple for dark mode
                    foregroundColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.black87 // Black text for light mode
                        : Colors.white, // White text for dark mode
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    elevation: 0, // Flat design
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // More rounded (pill-shaped)
                    ),
                  ),
                  child: Text(
                    isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
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
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF3B82F6) // Blue for light mode
                        : AppColors.purpleAccent, // Purple for dark mode
                    foregroundColor: Theme.of(context).brightness == Brightness.light
                        ? Colors.black87 // Black text for light mode
                        : Colors.white, // White text for dark mode
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    elevation: 0, // Flat design
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // More rounded (pill-shaped)
                    ),
                  ),
                  child: const Text(
                    'Message',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
}

