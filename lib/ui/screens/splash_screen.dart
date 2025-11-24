import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/logger.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/user_service.dart';
import '../../state/item_provider.dart';
import '../../state/theme_provider.dart';
import '../../app.dart';

class SplashScreen extends StatefulWidget {
  final bool enableAutoNavigate;

  const SplashScreen({super.key, this.enableAutoNavigate = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _fadeController;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  UserService? _userService;
  bool _blockedByBan = false;
  bool _hasNavigated = false;
  String? _banReason;
  DateTime? _banExpiresAt;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 3500), // 3.5 detik
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animations
    _fadeController.forward();

    // Start loading animation after first frame to avoid blocking tests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadingController.forward();
      }
    });

    final banCheck = _checkUserBanStatus();

    if (widget.enableAutoNavigate) {
      // Start preloading data di background
      _preloadData();

      banCheck.whenComplete(() {
        if (!mounted || _blockedByBan || _hasNavigated) return;
        _timer = Timer(const Duration(milliseconds: 4000), _navigateToRoot);
      });
    }
  }

  /// Preload data komik di background saat splash screen
  Future<void> _preloadData() async {
    try {
      // Load ThemeProvider first
      if (!mounted) return;
      ThemeProvider? themeProvider;
      try {
        themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      } catch (_) {}
      await themeProvider?.load();

      // Get ItemProvider dari context
      if (!mounted) return;
      ItemProvider? itemProvider;
      try {
        itemProvider = Provider.of<ItemProvider>(context, listen: false);
      } catch (_) {}

      // Start loading data di background
      await itemProvider?.init();
    } catch (e, stackTrace) {
      // Log preload errors but don't block app startup
      AppLogger.warning(
        'Failed to preload data during splash screen',
        e,
        stackTrace,
      );
    }
  }

  Future<void> _checkUserBanStatus() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final service = _userService ??= UserService();
      final UserProfile? profile = await service.fetchProfile(user.uid);
      if (!mounted || profile == null) return;

      if (profile.isBanned) {
        _timer?.cancel();
        setState(() {
          _blockedByBan = true;
          _banReason = profile.lastSanctionReason;
          _banExpiresAt = profile.bannedUntil;
        });
      }
    } catch (error, stackTrace) {
      AppLogger.warning('Failed to check ban status', error, stackTrace);
    }
  }

  void _navigateToRoot() {
    if (!mounted || _blockedByBan || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const _RootGate()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: const Center(child: _SplashContent()),
              );
            },
          ),
          if (_blockedByBan) _buildBanOverlay(context),
        ],
      ),
    );
  }

  Widget _buildBanOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final reason = (_banReason?.trim().isNotEmpty ?? false)
        ? _banReason!.trim()
        : 'Akun Anda telah diblokir oleh admin.';
    final durationText = _banExpiresAt != null
        ? 'Penangguhan berlaku hingga ${_formatDateTime(_banExpiresAt!)}.'
        : 'Penangguhan berlaku sampai admin mencabutnya.';

    return Positioned.fill(
      child: Container(
        color: theme.colorScheme.surface.withOpacity(0.95),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 48, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Akun Diblokir',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  reason,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  durationText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Hubungi tim admin jika menurutmu ini adalah kesalahan.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _SplashContent extends StatefulWidget {
  const _SplashContent();

  @override
  State<_SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<_SplashContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(
        milliseconds: 3500,
      ), // Sama dengan main controller
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    // Start loading animation after image appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadingController.forward();
      }
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context);
    } catch (_) {}
    final isDarkMode =
        themeProvider?.isDarkMode ??
        Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Full screen background image based on theme
        Positioned.fill(
          child: Image.asset(
            isDarkMode
                ? 'assets/images/splashscreendarkmode.png'
                : 'assets/images/splashscreenlightmode.png',
            fit: BoxFit.cover,
          ),
        ),

        // Overlay untuk readability (berbeda untuk dark/light mode)
        Positioned.fill(
          child: Container(
            color: isDarkMode
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),

        // Bottom loading section - di ujung bawah sekali
        Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Small animated loading bar
              Container(
                width: screenWidth * 0.4, // Lebih kecil
                height: 3, // Lebih tipis
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(1.5),
                ),
                child: AnimatedBuilder(
                  animation: _loadingAnimation,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        // Background bar
                        Container(
                          width: double.infinity,
                          height: 3,
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        // Progress bar with gradient
                        Container(
                          width: (screenWidth * 0.4) * _loadingAnimation.value,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDarkMode
                                  ? [
                                      AppColors.purpleAccent,
                                      Color(0xFF9C27B0),
                                      Color(0xFFE91E63),
                                    ]
                                  : [
                                      Color(0xFF3B82F6), // Blue 500
                                      Color(0xFF60A5FA), // Blue 400
                                      Color(0xFF93C5FD), // Blue 300
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(1.5),
                            boxShadow: [
                              BoxShadow(
                                color: isDarkMode
                                    ? AppColors.purpleAccent.withValues(
                                        alpha: 0.8,
                                      )
                                    : Color(0xFF3B82F6).withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Loading text with fade animation
              AnimatedBuilder(
                animation: _loadingAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.6 + (_loadingAnimation.value * 0.4),
                    child: Text(
                      'Loading manga collection...',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: isDarkMode ? Colors.black : Colors.white,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Root gate mengarahkan ke Auth/Main yang sudah ada di app.dart
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    return const NandogamiApp();
  }
}
