import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A gradient button widget for authentication actions.
/// Uses different gradient colors for light and dark themes.
class AuthGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  
  const AuthGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF9B5DE5), const Color(0xFF7C3AED)] // Purple gradient for dark
                  : [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue gradient for light
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.all(ui.Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

