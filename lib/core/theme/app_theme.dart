import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Brand core
  static const Color navy = Color(0xFF0D1B3E); // dark navy
  static const Color navyMid = Color(0xFF162554); // mid-navy
  static const Color navyLight = Color(0xFF1E3A6E); // lighter navy accent

  // Teal/cyan
  static const Color teal = Color(0xFF7FECDC); // Get started btn
  static const Color tealDark = Color(0xFF3DD6C0); // borders
  static const Color tealDeep = Color(0xFF00B5A3); // active states

  // Background & surfaces
  static const Color bgWhite = Color(0xFFFFFFFF);
  static const Color bgLight = Color(0xFFF4F7FB); // overall screen bg
  static const Color fieldBg = Color(0xFFDEEAF4); // pill input field bg
  static const Color fieldBgAlt = Color(0xFFE8F1F9); // slightly lighter

  // Text
  static const Color textNavy = Color(0xFF0D1B3E); // primary text
  static const Color textDark = Color(0xFF1A2B4A); // body text
  static const Color textMid = Color(0xFF4A5E7A); // secondary/labels
  static const Color textHint = Color(0xFF8FA3BC); // hint/placeholder
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textTeal = Color(0xFF00B5A3);

  // Semantic
  static const Color success = Color(0xFF2EB87A);
  static const Color successBg = Color(0xFFE6F9F1);
  static const Color warning = Color(0xFFF5A623);
  static const Color error = Color(0xFFD94F4F);
  static const Color errorBg = Color(0xFFFFF0F0);

  // Role colours
  static const Color roleCollector = Color(0xFF4A90D9);
  static const Color rolePhysician = Color(0xFF0D1B3E);
  static const Color roleResearcher = Color(0xFF7B5EA7);

  // ID badge
  static const Color idBadgeBg = Color(0xFF0D1B3E);
  static const Color saveRed = Color(0xFFE53935);
}

// -------------
// THEME
// -------------
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: AppColors.bgLight,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.navy,
        onPrimary: AppColors.textWhite,
        primaryContainer: AppColors.fieldBg,
        secondary: AppColors.teal,
        onSecondary: AppColors.navy,
        secondaryContainer: AppColors.teal,
        onSecondaryContainer: AppColors.navy,
        error: AppColors.error,
        onError: AppColors.textWhite,
        surface: AppColors.bgWhite,
        onSurface: AppColors.textNavy,
        outline: AppColors.fieldBg,
        onSurfaceVariant: AppColors.textMid,
      ),

      // - AppBar ---
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgLight,
        foregroundColor: AppColors.textNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textNavy,
        ),
        iconTheme: IconThemeData(color: AppColors.textNavy, size: 22),
      ),

      // - Text ---
      textTheme: const TextTheme(
        // Big display
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: AppColors.textNavy,
          letterSpacing: -0.5,
          height: 1.15,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: AppColors.textNavy,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textNavy,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textNavy,
        ),
        titleLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textNavy,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textNavy,
        ),
        bodyLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textMid,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textNavy,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMid,
          letterSpacing: 0.2,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
          letterSpacing: 0.3,
        ),
      ),

      // -- Inputs - pill shape ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(color: AppColors.tealDeep, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMid,
        ),
        prefixIconColor: AppColors.textMid,
        suffixIconColor: AppColors.textMid,
      ),

      // -- Elevated Buttons ---------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // -- Outline Buttons -------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // -- Cards ---------
      cardTheme: CardThemeData(
        color: AppColors.bgWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),

      // -- BottomNav - teal bg
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.teal,
        selectedItemColor: AppColors.navy,
        unselectedItemColor: AppColors.navyLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: IconThemeData(size: 26),
        unselectedIconTheme: IconThemeData(size: 24),
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),

      // -- FAB --------
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.textWhite,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // -- Chip ---------
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.fieldBg,
        selectedColor: AppColors.navy,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMid,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.fieldBg,
        thickness: 1,
        space: 0,
      ),

      splashColor: AppColors.teal.withOpacity(0.2),
      highlightColor: AppColors.fieldBg,
    );
  }
}

// -------------------
// TEXT STYLE HELPERS
// -------------------
extension AppTextStyles on TextTheme {
  // page title, ie, Add new patient
  TextStyle get pageTitle => const TextStyle(
    fontFamily: 'Nunito',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textNavy,
    letterSpacing: -0.5,
    height: 1.1,
  );

  TextStyle get pageTitleWhite => const TextStyle(
    fontFamily: 'Nunito',
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textWhite,
    letterSpacing: -0.5,
    height: 1.1,
  );
}
