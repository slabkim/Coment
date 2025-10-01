import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants.dart';

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

  // ================= FIREBASE AUTH (opsional) =================
  Future<void> _doLogin() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailC.text.trim(),
        password: _passwordC.text.trim(),
      );
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Login gagal');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doSignup() async {
    if (!_signupKey.currentState!.validate()) return;
    if (!_agreeTerms.value) {
      setState(() => _error = 'Kamu harus menyetujui Syarat & Privasi.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailC.text.trim(),
        password: _passwordC.text.trim(),
      );
      // (opsional) update displayName
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        _usernameC.text.trim(),
      );
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Registrasi gagal');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailC.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Masukkan email dulu untuk reset password.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tautan reset dikirim ke email kamu.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Gagal mengirim tautan reset.');
    }
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.black,
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
                  // Avatar + Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF3B2A58,
                      ), // circle_purple_avatar feel
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Center(
                      child: Image.asset(
                        'assets/images/Coment Logo.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // App name
                  Text(
                    AppConst.appName,
                    style: const TextStyle(
                      color: AppColors.purpleAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtitle
                  const Text(
                    'Your personal manga, manhwa, and manhua recommendation app',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.whiteSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Tabs
                  Container(
                    height: 48,
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121316), // black_light feel
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            text: 'Login',
                            active: _isLogin,
                            onTap: () => setState(() => _isLogin = true),
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Forms
                  if (_isLogin)
                    _LoginForm(
                      formKey: _loginKey,
                      emailC: _emailC,
                      passwordC: _passwordC,
                      rememberMe: _rememberMe,
                      onForgot: _forgotPassword,
                    )
                  else
                    _SignupForm(
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
                    child: _GradientButton(
                      text: _isLogin ? 'Log In' : 'Sign Up',
                      onPressed: _isLogin ? _doLogin : _doSignup,
                    ),
                  ),

                  // Footer
                  SizedBox(height: width > 400 ? 50 : 30),
                  const Text(
                    '© 2025 Nandogami. All rights reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF7E7E7E), // white_disabled feel
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

// =================== WIDGETS ===================

class _TabButton extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;
  const _TabButton({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: active ? AppColors.purpleAccent : const Color(0xFF121316),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF8E8E8E),
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailC;
  final TextEditingController passwordC;
  final ValueNotifier<bool> rememberMe;
  final VoidCallback onForgot;

  const _LoginForm({
    required this.formKey,
    required this.emailC,
    required this.passwordC,
    required this.rememberMe,
    required this.onForgot,
  });

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          _OutlinedField(
            controller: widget.emailC,
            hint: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
              if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())) {
                return 'Email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _OutlinedField(
            controller: widget.passwordC,
            hint: 'Password',
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              return null;
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: widget.rememberMe,
                builder: (_, val, __) => Checkbox(
                  value: val,
                  onChanged: (x) => widget.rememberMe.value = x ?? false,
                  side: const BorderSide(color: Colors.white54),
                  checkColor: Colors.white,
                  activeColor: AppColors.purpleAccent,
                ),
              ),
              const Text(
                'Remember me',
                style: TextStyle(color: AppColors.whiteSecondary),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onForgot,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: AppColors.purpleAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignupForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameC;
  final TextEditingController emailC;
  final TextEditingController passwordC;
  final ValueNotifier<bool> agreeTerms;

  const _SignupForm({
    required this.formKey,
    required this.usernameC,
    required this.emailC,
    required this.passwordC,
    required this.agreeTerms,
  });

  @override
  State<_SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<_SignupForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          _OutlinedField(
            controller: widget.usernameC,
            hint: 'Username',
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Username wajib diisi';
              if (v.trim().length < 3) return 'Minimal 3 karakter';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _OutlinedField(
            controller: widget.emailC,
            hint: 'Email',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
              if (!RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim())) {
                return 'Email tidak valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _OutlinedField(
            controller: widget.passwordC,
            hint: 'Password',
            obscureText: _obscure,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password wajib diisi';
              if (v.length < 8) return 'Minimal 8 karakter';
              return null;
            },
          ),
          const SizedBox(height: 6),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Password must be at least 8 characters long',
              style: TextStyle(color: Color(0xFF7E7E7E), fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: widget.agreeTerms,
                builder: (_, val, __) => Checkbox(
                  value: val,
                  onChanged: (x) => widget.agreeTerms.value = x ?? false,
                  side: const BorderSide(color: Colors.white54),
                  checkColor: Colors.white,
                  activeColor: AppColors.purpleAccent,
                ),
              ),
              const Expanded(
                child: Text(
                  'I agree to the Terms of Service and Privacy Policy',
                  style: TextStyle(color: AppColors.whiteSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlinedField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const _OutlinedField({
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
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF121316), // black_light
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: _border(const Color(0xFF2A2E35)),
        focusedBorder: _border(AppColors.purpleAccent),
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

class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _GradientButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF9B5DE5), Color(0xFF7C3AED)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: const Center(
            child: Text(
              'Button',
              style: TextStyle(
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
