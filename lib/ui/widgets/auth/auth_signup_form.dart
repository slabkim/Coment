import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import 'auth_outlined_field.dart';

/// Sign-up form widget for authentication screens.
/// Handles username, email, password, and terms agreement.
class AuthSignupForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameC;
  final TextEditingController emailC;
  final TextEditingController passwordC;
  final ValueNotifier<bool> agreeTerms;

  const AuthSignupForm({
    super.key,
    required this.formKey,
    required this.usernameC,
    required this.emailC,
    required this.passwordC,
    required this.agreeTerms,
  });

  @override
  State<AuthSignupForm> createState() => _AuthSignupFormState();
}

class _AuthSignupFormState extends State<AuthSignupForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          AuthOutlinedField(
            controller: widget.usernameC,
            hint: 'Username',
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username is required';
              if (v.trim().length < 3) return 'Minimum 3 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
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
              if (v.length < 8) return 'Minimum 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Password must be at least 8 characters long',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: widget.agreeTerms,
                builder: (_, val, __) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Checkbox(
                    value: val,
                    onChanged: (x) => widget.agreeTerms.value = x ?? false,
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
              Expanded(
                child: Text(
                  'I agree to the Terms of Service and Privacy Policy',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

