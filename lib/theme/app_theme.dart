import 'package:flutter/material.dart';

/// Central color & style palette extracted from the UB Transport / Cambus
/// Figma design. Keep all raw hex values here so screens never hardcode
/// colors directly.
class AppColors {
  AppColors._();

  // Backgrounds
  static const cream = Color(0xFFFFFFFF); // main app background
  static const white = Color(0xFFFFFFFF);
  static const darkOlive = Color(0xFF12345B); // confirmation / header bg
  static const inputFill = Color(0xFFFFFFFF);
  static const chipFill = Color(0xFFEAF2FA);

  // Brand accents
  static const indigo = Color(0xFF1769AA); // primary blue / logo badge
  static const gold = Color(0xFFF2B705); // primary CTA button
  static const goldDark = Color(0xFFD99F00);
  static const teal = Color(0xFFF2B705); // prices, selected states
  static const tealDark = Color(0xFFD99F00);

  // Text
  static const textPrimary = Color(0xFF12345B);
  static const textSecondary = Color(0xFF55708C);
  static const textMuted = Color(0xFF8FA5B8);
  static const textOnDark = Color(0xFFFFFFFF);
  static const link = Color(0xFF1769AA);

  // Status
  static const danger = Color(0xFFE0483E);
  static const success = teal;
  static const seatBooked = Color(0xFFD3E0EC);
  static const border = Color(0xFFD5E2EE);
}

class AppTextStyles {
  AppTextStyles._();

  static const fontFamily = 'Inter';

  static const h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.indigo,
        primary: AppColors.indigo,
        secondary: AppColors.teal,
        surface: AppColors.cream,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.h2,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.indigo, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),
    );
  }
}
