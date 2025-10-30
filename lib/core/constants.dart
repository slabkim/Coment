import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConst {
  static const appName = 'Coment';
  static const baseUrl = 'https://example.com/api';
  
  // 🔐 SECURE: API keys loaded from .env file (not committed to git)
  // Create a .env file in project root with: GIPHY_API_KEY=your_key_here
  static String get giphyApiKey {
    final key = dotenv.env['GIPHY_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception(
        '❌ GIPHY_API_KEY not found!\n'
        '📝 Create a .env file in project root with:\n'
        'GIPHY_API_KEY=your_giphy_api_key_here\n'
        '🔑 Get free API key from: https://developers.giphy.com/'
      );
    }
    return key;
  }
  
  // Developer account UID (absolute admin - auto-moderator in all forums)
  static const developerUid = 'YBOVlOR7MIQAbp4e3sRb9GJ24Kg1'; // anandasubing190305@gmail.com
}

class AppColors {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const primaryDark = Color(0xFF1E40AF);
  static const whiteSecondary = Color(0xFFB8B8B8);
  static const purpleAccent = Color(0xFF9B5DE5);

  // Extended tokens adapted from old Android colors.xml
  static const purple200 = Color(0xFFBB86FC);
  static const purple500 = Color(0xFF6200EE);
  static const purple700 = Color(0xFF3700B3);

  // Modern gradient colors
  static const purplePrimary = Color(0xFF8B5CF6);
  static const purpleSecondary = Color(0xFFA855F7);
  static const purpleTertiary = Color(0xFFC084FC);

  // Accent colors for highlights
  static const pinkAccent = Color(0xFFEC4899);
  static const blueAccent = Color(0xFF3B82F6);
  static const tealAccent = Color(0xFF14B8A6);

  static const blackDark = Color(0xFF121212);
  static const blackMedium = Color(0xFF1E1E1E);
  static const blackLight = Color(0xFF2D2D2D);
  static const blackSurface = Color(0xFF1A1A1A);

  static const grayDark = Color(0xFF424242);
  static const grayMedium = Color(0xFF616161);
  static const grayLight = Color(0xFF757575);
  static const gray = Color(0xFF9E9E9E);

  static const green = Color(0xFF4CAF50);
  static const blue = Color(0xFF2196F3);
  static const red = Color(0xFFF44336);
  static const orange = Color(0xFFFF9800);
  static const yellow = Color(0xFFFFC107);
}
