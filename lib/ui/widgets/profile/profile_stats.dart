import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/follow_service.dart';
import '../../../data/services/reading_status_service.dart';
import '../../screens/user_list_screen.dart';
import '../../screens/reading_list_screen.dart';
import 'profile_stat_item.dart';

class ProfileStats extends StatelessWidget {
  final String userId;
  
  const ProfileStats({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final follow = FollowService();
    
    if (uid == null || uid != userId) {
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
            child: ProfileStatItem(
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
            child: ProfileStatItem(
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
              MaterialPageRoute(
                builder: (_) => const ReadingListScreen(),
              ),
            ),
            child: ProfileStatItem(
              label: 'Reads',
              value: (s.data?.length ?? 0).toString(),
            ),
          ),
        ),
      ],
    );
  }
}

