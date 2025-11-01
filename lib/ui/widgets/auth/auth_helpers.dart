import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import '../../../core/logger.dart';
import '../../../data/services/user_service.dart';

/// Helper functions for authentication operations
class AuthHelpers {
  static Future<bool> doLogin(
    BuildContext context, {
    required String email,
    required String password,
    required Function(bool) setBusy,
    required Function(String?) setError,
  }) async {
    setBusy(true);
    setError(null);
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      setError(e.message ?? 'Login failed');
      return false;
    } catch (e, stackTrace) {
      AppLogger.authError('Login', e, stackTrace);
      setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      if (context.mounted) {
        setBusy(false);
      }
    }
  }

  static Future<bool> doSignup(
    BuildContext context, {
    required String username,
    required String email,
    required String password,
    required Function(bool) setBusy,
    required Function(String?) setError,
  }) async {
    setBusy(true);
    setError(null);
    
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      // Update displayName
      await FirebaseAuth.instance.currentUser?.updateDisplayName(
        username.trim(),
      );
      
      final user = cred.user;
      if (user != null) {
        await UserService().ensureUserDoc(
          uid: user.uid,
          email: user.email ?? email.trim(),
          displayName: username.trim(),
          photoUrl: user.photoURL,
        );
      }
      
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      setError(e.message ?? 'Sign up failed');
      return false;
    } catch (e, stackTrace) {
      AppLogger.authError('Signup', e, stackTrace);
      setError('Sign up failed: ${e.toString()}');
      return false;
    } finally {
      if (context.mounted) {
        setBusy(false);
      }
    }
  }

  static Future<void> forgotPassword(
    BuildContext context, {
    required String email,
    required Function(String?) setError,
  }) async {
    final emailTrimmed = email.trim();
    if (emailTrimmed.isEmpty) {
      setError('Please enter your email to reset password.');
      return;
    }
    
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailTrimmed);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset link sent to your email.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setError(e.message ?? 'Failed to send reset link.');
    } catch (e, stackTrace) {
      AppLogger.authError('Forgot Password', e, stackTrace);
      setError('Failed to send reset link: ${e.toString()}');
    }
  }

  static Future<bool> signInWithGoogle(
    BuildContext context, {
    required Function(bool) setBusy,
    required Function(String?) setError,
  }) async {
    setBusy(true);
    setError(null);
    
    try {
      // Configure Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        setBusy(false);
        return false;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        await UserService().ensureUserDoc(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
          photoUrl: user.photoURL,
        );
      }
      
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      // Specific error handling for ApiException: 10
      if (e.code == 'sign_in_failed' && e.message?.contains('ApiException: 10') == true) {
        AppLogger.warning('DEVELOPER_ERROR: OAuth configuration issue. Check Firebase and Google Cloud Console settings.');
      }
      AppLogger.authError('Google Sign-In', e);
      setError('Google Sign-In failed: ${e.toString()}');
      return false;
    } catch (e, stackTrace) {
      AppLogger.authError('Google Sign-In', e, stackTrace);
      setError('Google Sign-In failed: ${e.toString()}');
      return false;
    } finally {
      if (context.mounted) {
        setBusy(false);
      }
    }
  }
}

