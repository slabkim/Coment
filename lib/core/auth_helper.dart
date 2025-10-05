import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../ui/screens/login_register_screen.dart';

class AuthHelper {
  /// Cek apakah user sudah login
  static bool isLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  /// Cek dan redirect ke login jika belum login
  /// Return true jika sudah login, false jika redirect ke login
  static Future<bool> requireAuth(BuildContext context) async {
    if (isLoggedIn()) {
      return true;
    }

    // Push ke login screen dan tunggu hasil
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const LoginRegisterScreen(),
      ),
    );

    // Return true jika login berhasil, false jika dibatalkan
    return result ?? false;
  }

  /// Cek dan show dialog konfirmasi sebelum redirect ke login
  static Future<bool> requireAuthWithDialog(BuildContext context, String action) async {
    if (isLoggedIn()) {
      return true;
    }

    // Show dialog konfirmasi
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: Text('You need to login to $action. Do you want to login now?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Login'),
          ),
        ],
      ),
    );

    if (shouldLogin == true) {
      return await requireAuth(context);
    }

    return false;
  }

  /// Get current user
  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  /// Logout user
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
