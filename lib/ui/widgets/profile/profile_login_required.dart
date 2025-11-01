import 'package:flutter/material.dart';
import '../../../core/auth_helper.dart';
import '../../../core/constants.dart';
import '../../screens/profile_screen.dart';

class ProfileLoginRequired extends StatelessWidget {
  const ProfileLoginRequired({super.key});

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
              ),
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
                backgroundColor: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF3B82F6) // Blue for light mode
                    : AppColors.purpleAccent, // Purple for dark mode
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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

