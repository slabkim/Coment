import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
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
  late Animation<double> _loadingAnimation;

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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    
    // Start loading animation after a short delay
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _loadingController.forward();
      }
    });

    if (widget.enableAutoNavigate) {
      // Start preloading data di background
      _preloadData();
      
      // Navigate after animations complete (4 detik)
      _timer = Timer(const Duration(milliseconds: 4000), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const _RootGate()),
        );
      });
    }
  }

  /// Preload data komik di background saat splash screen
  Future<void> _preloadData() async {
    try {
      // Load ThemeProvider first
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      await themeProvider.load();
      
      // Get ItemProvider dari context
      final itemProvider = Provider.of<ItemProvider>(context, listen: false);
      
      // Start loading data di background
      await itemProvider.init();
    } catch (e) {
      // Silently ignore preload errors
    }
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
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: const Center(
              child: _SplashContent(),
            ),
          );
        },
      ),
    );
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
      duration: const Duration(milliseconds: 3500), // Sama dengan main controller
      vsync: this,
    );

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    ));

    // Start loading animation after image appears
    Future.delayed(const Duration(milliseconds: 500), () {
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Safe access to ThemeProvider with listening
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.isDarkMode;

    return Stack(
      children: [
        // Full screen background image based on theme
        Positioned.fill(
          child: Image.asset(
            isDarkMode 
              ? 'assets/images/splashscreendarkmode.png'
              : 'assets/images/splashscreenlightmode.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image not found
              return Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: Text(
                    'Coment',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
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
                                  ? AppColors.purpleAccent.withValues(alpha: 0.8)
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
                        color: isDarkMode 
                          ? Colors.white70
                          : Colors.black54,
                        fontSize: 10,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: isDarkMode 
                              ? Colors.black
                              : Colors.white,
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
      },
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
