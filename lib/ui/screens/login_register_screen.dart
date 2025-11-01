import 'package:flutter/material.dart';
import '../widgets/auth/auth_header.dart';
import '../widgets/auth/auth_tab_button.dart';
import '../widgets/auth/auth_login_form.dart';
import '../widgets/auth/auth_signup_form.dart';
import '../widgets/auth/auth_gradient_button.dart';
import '../widgets/auth/auth_google_sign_in_button.dart';
import '../widgets/auth/auth_helpers.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({super.key});

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  // tab: true = login, false = signup
  bool _isLogin = true;

  // --- controllers ---
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _usernameC = TextEditingController(); // untuk signup
  final _rememberMe = ValueNotifier<bool>(false);
  final _agreeTerms = ValueNotifier<bool>(false);

  // --- form keys ---
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();

  bool _busy = false;
  String? _error; // tampilkan error Firebase

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    _usernameC.dispose();
    _rememberMe.dispose();
    _agreeTerms.dispose();
    super.dispose();
  }


  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AbsorbPointer(
        absorbing: _busy,
        child: Stack(
          children: [
            // MAIN SCROLL
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.paddingOf(context).top + 16),
                  // Header (Avatar + Logo + App Name)
                  const AuthHeader(),
                  const SizedBox(height: 28),

                  // Tabs
                  Container(
                    height: 48,
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[200] // Light grey for light mode
                          : const Color(0xFF121316), // Dark for dark mode
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AuthTabButton(
                            text: 'Login',
                            active: _isLogin,
                            onTap: () => setState(() => _isLogin = true),
                          ),
                        ),
                        Expanded(
                          child: AuthTabButton(
                            text: 'Sign Up',
                            active: !_isLogin,
                            onTap: () => setState(() => _isLogin = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Welcome / Create account title
                  Text(
                    _isLogin ? 'Welcome back' : 'Create an account',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Forms
                  if (_isLogin)
                    AuthLoginForm(
                      formKey: _loginKey,
                      emailC: _emailC,
                      passwordC: _passwordC,
                      rememberMe: _rememberMe,
                      onForgot: () => AuthHelpers.forgotPassword(
                        context,
                        email: _emailC.text,
                        setError: (error) => setState(() => _error = error),
                      ),
                    )
                  else
                    AuthSignupForm(
                      formKey: _signupKey,
                      usernameC: _usernameC,
                      emailC: _emailC,
                      passwordC: _passwordC,
                      agreeTerms: _agreeTerms,
                    ),

                  // Error text
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],

                  const SizedBox(height: 22),
                  // Submit button (gradient)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: AuthGradientButton(
                      text: _isLogin ? 'Log In' : 'Sign Up',
                      onPressed: _isLogin
                          ? () {
                              if (!_loginKey.currentState!.validate()) return;
                              AuthHelpers.doLogin(
                                context,
                                email: _emailC.text,
                                password: _passwordC.text,
                                setBusy: (busy) => setState(() => _busy = busy),
                                setError: (error) => setState(() => _error = error),
                              );
                            }
                          : () {
                              if (!_signupKey.currentState!.validate()) return;
                              if (!_agreeTerms.value) {
                                setState(() => _error = 'Kamu harus menyetujui Syarat & Privasi.');
                                return;
                              }
                              AuthHelpers.doSignup(
                                context,
                                username: _usernameC.text,
                                email: _emailC.text,
                                password: _passwordC.text,
                                setBusy: (busy) => setState(() => _busy = busy),
                                setError: (error) => setState(() => _error = error),
                              );
                            },
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'atau',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google Sign-In button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: AuthGoogleSignInButton(
                      onPressed: () => AuthHelpers.signInWithGoogle(
                        context,
                        setBusy: (busy) => setState(() => _busy = busy),
                        setError: (error) => setState(() => _error = error),
                      ),
                    ),
                  ),

                  // Footer
                  SizedBox(height: width > 400 ? 50 : 30),
                  Text(
                    '© 2025 Nandogami. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // LOADING overlay
            if (_busy)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0xAA000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
