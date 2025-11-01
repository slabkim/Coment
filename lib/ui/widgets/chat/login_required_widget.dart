import 'package:flutter/material.dart';
import '../../../core/auth_helper.dart';
import '../../../core/constants.dart';
import '../../screens/chat_list_screen.dart';

/// Widget for displaying a login required message on chat screen.
/// Shows a message and login button when user is not authenticated.
class LoginRequiredWidget extends StatelessWidget {
  const LoginRequiredWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
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
              'Please login to send and receive messages',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final success = await AuthHelper.requireAuth(context);
                if (success && context.mounted) {
                  // Refresh the screen to show chat
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ChatListScreen()),
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

