import 'package:flutter/material.dart';
import '../../../core/constants.dart';

/// A styled text field widget for authentication forms.
/// Supports both light and dark themes with appropriate styling.
class AuthOutlinedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const AuthOutlinedField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.black45,
        ),
        filled: true,
        fillColor: isDark
            ? const Color(0xFF121316) // Dark for dark mode
            : Colors.grey[100], // Light grey for light mode
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: _border(
          isDark ? const Color(0xFF2A2E35) : Colors.grey[300]!,
        ),
        focusedBorder: _border(
          isDark ? AppColors.purpleAccent : const Color(0xFF3B82F6),
        ),
        errorBorder: _border(Colors.redAccent),
        focusedErrorBorder: _border(Colors.redAccent),
        suffixIcon: suffixIcon,
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color),
  );
}

