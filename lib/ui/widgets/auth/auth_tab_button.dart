import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// A tab button widget for authentication screens.
/// Supports active and inactive states with theme-aware styling.
class AuthTabButton extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;
  
  const AuthTabButton({
    super.key,
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: active
              ? (isDark ? AppColors.purpleAccent : const Color(0xFF3B82F6)) // Purple for dark, blue for light
              : (isDark ? const Color(0xFF121316) : Colors.grey[200]), // Dark grey for dark, light grey for light
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active
                  ? (isDark ? Colors.white : Colors.black87) // White for dark, black for light when active
                  : (isDark ? const Color(0xFF8E8E8E) : Colors.grey[600]), // Grey for inactive
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

