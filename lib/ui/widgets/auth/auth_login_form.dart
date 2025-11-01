import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import 'auth_outlined_field.dart';

/// Login form widget for authentication screens.
/// Handles email, password, and remember me functionality.
class AuthLoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailC;
  final TextEditingController passwordC;
  final ValueNotifier<bool> rememberMe;
  final VoidCallback onForgot;

  const AuthLoginForm({
    super.key,
    required this.formKey,
    required this.emailC,
    required this.passwordC,
    required this.rememberMe,
    required this.onForgot,
  });

  @override
  State<AuthLoginForm> createState() => _AuthLoginFormState();
}

class _AuthLoginFormState extends State<AuthLoginForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          AuthOutlinedField(
            controller: widget.emailC,
            hint: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())) {
                return 'Invalid email format';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          AuthOutlinedField(
            controller: widget.passwordC,
            hint: 'Password',
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: widget.rememberMe,
                builder: (_, val, __) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Checkbox(
                    value: val,
                    onChanged: (x) => widget.rememberMe.value = x ?? false,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    checkColor: Colors.white,
                    activeColor: isDark
                        ? AppColors.purpleAccent
                        : const Color(0xFF3B82F6),
                  );
                },
              ),
              Text(
                'Remember me',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onForgot,
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.purpleAccent
                        : const Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

