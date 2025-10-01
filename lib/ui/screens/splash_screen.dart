import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../app.dart';

class SplashScreen extends StatefulWidget {
  final bool enableAutoNavigate;

  const SplashScreen({super.key, this.enableAutoNavigate = true});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.enableAutoNavigate) {
      // Simple delay agar terasa splash
      _timer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const _RootGate()));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.black,
      body: Center(child: _Logo()),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.menu_book, color: AppColors.purpleAccent, size: 64),
        SizedBox(height: 12),
        Text(
          AppConst.appName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
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
