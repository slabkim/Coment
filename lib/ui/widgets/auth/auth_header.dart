import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// Header widget for authentication screens (login/register).
/// Displays the app logo, name, and subtitle.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF3B82F6).withOpacity(0.1) // Light blue for light mode
                : const Color(0xFF3B2A58), // Purple for dark mode
            shape: BoxShape.circle,
          ),
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: Image.asset(
              'assets/images/comentlogo.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppConst.appName,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF3B82F6) // Blue for light mode
                : AppColors.purpleAccent, // Purple for dark mode
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Your personal manga, manhwa, and manhua recommendation app',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}