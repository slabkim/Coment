import 'package:flutter/material.dart';

import 'constants.dart';

/// Centralized app theme and design tokens.
class ComentTheme {
  const ComentTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: AppColors.purpleAccent,
        surface: AppColors.blackSurface,
        onSurface: AppColors.white,
        secondary: AppColors.purple500,
        onSurfaceVariant: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.black,
      textTheme: const TextTheme(bodyMedium: TextStyle(color: AppColors.white)),
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
        primary: Color(0xFF2563EB), // Blue 600 - biru lebih gelap untuk kontras
        surface: Color(0xFFFEFEFE), // Putih sedikit lebih lembut
        onSurface: Color(0xFF0F172A), // Slate 900 - hitam lebih pekat
        secondary: Color(0xFF3B82F6), // Blue 500
        background: Color(0xFFF1F5F9), // Slate 100 - abu-abu sangat muda
        onBackground: Color(0xFF0F172A), // Slate 900
        surfaceContainerHighest: Color(0xFFE2E8F0), // Slate 200 - abu-abu muda
        onSurfaceVariant: Color(0xFF475569), // Slate 600 - abu-abu lebih gelap
        outline: Color(0xFFCBD5E1), // Slate 300
        primaryContainer: Color(0xFFDBEAFE), // Blue 100
        onPrimaryContainer: Color(0xFF1E40AF), // Blue 800
      ),
      scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100 - abu-abu sangat muda
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF1F5F9), // Slate 100 - abu-abu sangat muda
        foregroundColor: Color(0xFF0F172A), // Slate 900 - hitam pekat
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF0F172A)), // Slate 900 - hitam pekat
        bodyMedium: TextStyle(color: Color(0xFF0F172A)), // Slate 900 - hitam pekat
        bodySmall: TextStyle(color: Color(0xFF475569)), // Slate 600 - abu-abu gelap
        titleLarge: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold), // Slate 900
        titleMedium: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600), // Slate 900
        titleSmall: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w500), // Slate 900
        labelLarge: TextStyle(color: Color(0xFF0F172A)), // Slate 900
        labelMedium: TextStyle(color: Color(0xFF475569)), // Slate 600
        labelSmall: TextStyle(color: Color(0xFF64748B)), // Slate 500
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC), // Slate 50 - lebih terang
        hintStyle: const TextStyle(color: Color(0xFF64748B)), // Slate 500 - lebih gelap
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.horizontalPadding,
          vertical: AppDimens.verticalPadding,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)), // Slate 300
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2), // Blue 600
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
          borderSide: const BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
          borderSide: const BorderSide(color: AppColors.red, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFEFEFE), // Putih lembut
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // Blue 600 - lebih gelap
          foregroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // Blue 600 - lebih gelap
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB), // Blue 600 - lebih gelap
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A), // Slate 900 - hitam pekat
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(color: Color(0xFF64748B)), // Slate 500 - lebih gelap
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.all(const Color(0xFF2563EB)), // Blue 600
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFF8FAFC), // Slate 50 - abu-abu sangat muda
        selectedItemColor: Color(0xFF2563EB), // Blue 600 - lebih gelap
        unselectedItemColor: Color(0xFF64748B), // Slate 500 - lebih gelap
        elevation: 1,
        type: BottomNavigationBarType.fixed,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFCBD5E1), // Slate 300 - lebih gelap
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: Color(0xFF0F172A), // Slate 900 - hitam pekat
        iconColor: Color(0xFF475569), // Slate 600 - abu-abu gelap
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
