import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'edit_profile_screen.dart';
import 'user_list_screen.dart';
import 'reading_list_screen.dart';
import 'chat_list_screen.dart';
import 'recommendations_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.black,
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 8),
          const Center(
            child: Text('Your Name', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
          _tile(
            context,
            icon: Icons.message,
            title: 'Direct Messages',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            ),
          ),
          _tile(
            context,
            icon: Icons.people,
            title: 'Followers',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserListScreen(title: 'Followers')),
            ),
          ),
          _tile(
            context,
            icon: Icons.person_add,
            title: 'Following',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserListScreen(title: 'Following')),
            ),
          ),
          _tile(
            context,
            icon: Icons.menu_book,
            title: 'Reading List',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReadingListScreen()),
            ),
          ),
          _tile(
            context,
            icon: Icons.recommend,
            title: 'User Recommendations',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecommendationsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _tile(BuildContext context, {required IconData icon, required String title, VoidCallback? onTap}) {
  return Column(
    children: [
      ListTile(
        leading: Icon(icon, color: AppColors.white),
        title: Text(title, style: const TextStyle(color: AppColors.white)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.whiteSecondary),
        onTap: onTap,
      ),
      const Divider(height: 1, color: Color(0xFF22252B)),
    ],
  );
}
