import 'package:flutter/material.dart';
import '../../core/constants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      body: const Center(
        child: Text('Profile Screen', style: TextStyle(color: AppColors.white)),
      ),
    );
  }
}
