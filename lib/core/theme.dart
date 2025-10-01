import 'package:flutter/material.dart';

import 'constants.dart';

/// Centralized app theme and design tokens.
class NandogamiTheme {
  const NandogamiTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.purpleAccent,
        surface: AppColors.blackSurface,
        onSurface: AppColors.white,
        secondary: AppColors.purple500,
        background: AppColors.black,
        onBackground: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.black,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blackLight,
        hintStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.horizontalPadding,
          vertical: AppDimens.verticalPadding,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
          borderSide: const BorderSide(color: AppColors.grayDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
          borderSide: const BorderSide(color: AppColors.purpleAccent),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: Colors.white54),
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.all(AppColors.purpleAccent),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.blackSurface,
        selectedItemColor: AppColors.purpleAccent,
        unselectedItemColor: AppColors.whiteSecondary,
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.purpleAccent,
        surface: Colors.white,
        onSurface: Colors.black,
        secondary: AppColors.purple500,
        background: Colors.white,
        onBackground: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF2F3F5),
        hintStyle: const TextStyle(color: Colors.black54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.horizontalPadding,
          vertical: AppDimens.verticalPadding,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
          borderSide: const BorderSide(color: Color(0xFFE2E4E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
          borderSide: const BorderSide(color: AppColors.purpleAccent),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.purpleAccent,
        unselectedItemColor: Colors.black54,
      ),
    );
  }
}

/// Spacing and size tokens derived from old dimens.xml
class AppDimens {
  const AppDimens._();

  static const double horizontalPadding = 14; // maps ~16dp with tighter feel
  static const double verticalPadding = 14;
  static const double chipRadius = 12;
  static const double fieldRadius = 10;
}


