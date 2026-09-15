import 'package:flutter/material.dart';

class TibokColors {
  const TibokColors._();

  // Main Tibok brand color.
  static const Color primary = Color(0xFFC83C4A);

  static const Color primaryDark = Color(0xFF8E2631);

  static const Color background = Color(0xFFF7F7F5);

  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF242426);

  static const Color textSecondary = Color(0xFF606168);

  static const Color outline = Color(0xFFDEDFE2);

  static const Color softPrimary = Color(0xFFFFE9EB);

  static const Color success = Color(0xFF2E7D32);

  static const Color warning = Color(0xFFB26A00);

  static const Color danger = Color(0xFFB3261E);
}

class TibokTheme {
  const TibokTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: TibokColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: TibokColors.primary,
      onPrimary: Colors.white,
      primaryContainer: TibokColors.softPrimary,
      onPrimaryContainer: TibokColors.primaryDark,
      surface: TibokColors.surface,
      onSurface: TibokColors.textPrimary,
      outline: TibokColors.outline,
      error: TibokColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: TibokColors.background,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: TibokColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: TibokColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: TibokColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          height: 1.40,
          color: TibokColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          height: 1.40,
          color: TibokColors.textPrimary,
        ),
        bodySmall: TextStyle(
          height: 1.35,
          color: TibokColors.textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: TibokColors.background,
        foregroundColor: TibokColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: TibokColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: TibokColors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            20,
          ),
          side: const BorderSide(
            color: TibokColors.outline,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TibokColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: const BorderSide(
            color: TibokColors.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: const BorderSide(
            color: TibokColors.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: const BorderSide(
            color: TibokColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: const BorderSide(
            color: TibokColors.danger,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
          borderSide: const BorderSide(
            color: TibokColors.danger,
            width: 2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(
            48,
            52,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            48,
            52,
          ),
          elevation: 0,
          backgroundColor: TibokColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(
            48,
            52,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          side: const BorderSide(
            color: TibokColors.outline,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            48,
            48,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 4,
        ),
        iconColor: TibokColors.textSecondary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: TibokColors.surface,
        indicatorColor: TibokColors.softPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: TibokColors.outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: TibokColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: TibokColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            22,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: TibokColors.primary,
      ),
    );
  }
}
