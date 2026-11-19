import 'package:flutter/material.dart';

/// AppTheme defines Tracky's sleek White & Black aesthetic with minimal orange touches.
/// Features stark monochrome elegance, crisp typography, generous whitespace,
/// and micro orange athletic accents.
class AppTheme {
  // White & Black Palette
  static const Color background = Color(0xFFFAFAFA); // Crisp ultra-light canvas
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Pure white
  static const Color surface = Color(0xFFFFFFFF); // Pure white cards
  static const Color surfaceMuted = Color(0xFFF4F4F5); // Zinc-100 subtle pill
  static const Color border = Color(0xFFE4E4E7); // Zinc-200 minimal border
  static const Color borderLight = Color(0xFFF4F4F5);

  // Black Primary & Dark Elements
  static const Color primaryBlack = Color(0xFF09090B); // Deep crisp black
  static const Color secondaryBlack = Color(0xFF18181B);
  static const Color textPrimary = Color(0xFF09090B); // Pure black typography
  static const Color textSecondary = Color(0xFF52525B); // Zinc-600
  static const Color textMuted = Color(0xFFA1A1AA); // Zinc-400

  // Minimal Athletic Orange Accents
  static const Color accentOrange = Color(0xFFFF5500); // Electric athletic orange
  static const Color accentOrangeLight = Color(0xFFFFF1EB); // Subtle orange wash
  static const Color accentOrangeBorder = Color(0xFFFFD8C2);

  // Error
  static const Color errorRed = Color(0xFFDC2626);
  static const Color errorRedLight = Color(0xFFFEF2F2);

  static ThemeData get whiteAndBlackTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryBlack,
        onPrimary: Colors.white,
        secondary: accentOrange,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        error: errorRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlack, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        suffixStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryBlack,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryBlack,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
