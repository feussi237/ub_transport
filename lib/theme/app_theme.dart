import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';


class AppColors {
  AppColors._();

  // Backgrounds & Surfaces
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFEEF3F8);
  static const surfaceElevated = Color(0xFFFFFFFF);

  // Primary Brand (Deep Ocean Blue)
  static const primary = Color(0xFF1B3A6B);
  static const primaryLight = Color(0xFF2D5A9E);
  static const primaryDark = Color(0xFF0F264A);

  // Secondary Brand (Sunset Gold/Amber)
  static const secondary = Color(0xFFFFB703);
  static const secondaryLight = Color(0xFFFFCC33);
  static const secondaryDark = Color(0xFFE6A200);

  // Accent Colors
  static const accent = Color(0xFF00A7A0);
  static const accentLight = Color(0xFF33C4BF);
  static const accentSoft = Color(0xFFE6FAFA);

  // Success / Confirmation (Deep Blue-Gradient Header)
  static const primaryGradientStart = Color(0xFF1B3A6B);
  static const primaryGradientEnd = Color(0xFF2D5A9E);
  static const secondaryGradientStart = Color(0xFFFFB703);
  static const secondaryGradientEnd = Color(0xFFFF9A3D);

  // Chips & Tags
  static const chipPrimary = Color(0xFFE8F0FB);
  static const chipGold = Color(0xFFFFF4D6);
  static const chipSuccess = Color(0xFFE6F7F6);

  // Input Fields
  static const inputFill = Color(0xFFF0F4F8);
  static const inputBorder = Color(0xFFD5DFEA);
  static const inputBorderFocus = Color(0xFF1B3A6B);

  // Text Colors
  static const textPrimary = Color(0xFF0F264A);
  static const textSecondary = Color(0xFF4A607C);
  static const textMuted = Color(0xFF7A8EA6);
  static const textOnDark = Color(0xFFFFFFFF);
  static const link = Color(0xFF2D5A9E);
  static const linkUnderline = Color(0xFFFFB703);

  // Status & States
  static const success = Color(0xFF22A55C);
  static const successLight = Color(0xFFDFF5E8);
  static const warning = Color(0xFFFF9A3D);
  static const warningLight = Color(0xFFFFF0DE);
  static const danger = Color(0xFFE54D42);
  static const dangerLight = Color(0xFFFDE6E3);
  static const info = Color(0xFF2D5A9E);
  static const infoLight = Color(0xFFE6EEF9);

  // Booking / Seats
  static const seatAvailable = Color(0xFFFFFFFF);
  static const seatSelected = Color(0xFFFFB703);
  static const seatBooked = Color(0xFFD9E4F0);
  static const seatBorder = Color(0xFFC5D3E3);

  // Borders & Dividers
  static const border = Color(0xFFE3EBF3);
  static const borderLight = Color(0xFFEDF2F7);
  static const divider = Color(0xFFE8EEF5);

  // Legacy aliases for backward compatibility
  static const cream = background;
  static const white = surface;
  static const darkOlive = primary;
  static const indigo = primary;
  static const gold = secondary;
  static const goldDark = secondaryDark;
  static const teal = secondary;
  static const tealDark = secondaryDark;
  static const chipFill = chipPrimary;
}

class AppTextStyles {
  AppTextStyles._();

  static const fontFamily = 'Inter';

  static const display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const h1OnDark = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnDark,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const h2OnDark = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textOnDark,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static const subtitleOnDark = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFFB8C5D6),
    height: 1.45,
  );

  static const captionSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    height: 1.3,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const labelSection = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.2,
  );

  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const bodyBold = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static const buttonOnDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static const price = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    color: AppColors.primary,
    height: 1.2,
  );

  static const priceSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    height: 1.2,
  );

  static const badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    height: 1.2,
    letterSpacing: 0.3,
  );
}

class AppShadows {
  AppShadows._();

  static const xs = [
    BoxShadow(
      color: Color(0x1A1B3A6B),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const sm = [
    BoxShadow(
      color: Color(0x1F1B3A6B),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const md = [
    BoxShadow(
      color: Color(0x241B3A6B),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const lg = [
    BoxShadow(
      color: Color(0x291B3A6B),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const gold = [
    BoxShadow(
      color: Color(0x40FFB703),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

class AppGradients {
  AppGradients._();

  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
  );

  static const secondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondaryGradientStart, AppColors.secondaryGradientEnd],
  );

  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1B3A6B),
      Color(0xFF2D5A9E),
      Color(0xFF3A6BB5),
    ],
    stops: [0.0, 0.6, 1.0],
  );

  static const cardOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x66000000)],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnDark,
        primaryContainer: AppColors.infoLight,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.primaryDark,
        secondaryContainer: AppColors.chipGold,
        onSecondaryContainer: AppColors.primaryDark,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.textSecondary,
        error: AppColors.danger,
        onError: AppColors.textOnDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.h2,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.inputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primaryDark,
          disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.primaryDark.withValues(alpha: 0.5),
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          shadowColor: const Color(0x40FFB703),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 8,
        shadowColor: const Color(0x331B3A6B),
        indicatorColor: AppColors.chipGold,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primary);
          }
          return const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 26);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        dragHandleSize: Size(44, 4),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: AppTextStyles.h2,
        contentTextStyle: AppTextStyles.body,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnDark),
        side: const BorderSide(color: AppColors.primary, width: 1.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textMuted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.secondary;
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary.withValues(alpha: 0.3);
          return AppColors.border;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondary,
        linearTrackColor: Color(0xFFEEF3F8),
        circularTrackColor: Color(0xFFEEF3F8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: const TextStyle(color: AppColors.textOnDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: AppColors.textSecondary,
        tileColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipPrimary,
        selectedColor: AppColors.primary,
        disabledColor: Color(0xFFEEF3F8),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        secondaryLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textOnDark),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        side: BorderSide.none,
        showCheckmark: false,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.textOnDark,
        size: 24,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.chipGold,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
      ),
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: const ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: const FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
