// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Neutral palette inspired by aged paper and warm stone
  static const Color cream = Color(0xFFF7F4EF);
  static const Color warmWhite = Color(0xFFFBF9F6);
  static const Color softTan = Color(0xFFE8E1D6);
  static const Color warmGray = Color(0xFFB5AFA7);
  static const Color mediumGray = Color(0xFF7A746C);
  static const Color darkGray = Color(0xFF3D3830);
  static const Color ink = Color(0xFF1C1915);

  // Accent colors for note cards - warm, muted
  static const List<Color> noteColors = [
    Color(0xFFF5EDD8), // warm parchment
    Color(0xFFE8F0E9), // sage mist
    Color(0xFFEDE8F5), // lavender dusk
    Color(0xFFF5E8E8), // blush rose
    Color(0xFFE8EFF5), // pale sky
    Color(0xFFF5F0E8), // golden sand
  ];

  // Dark mode
  static const Color darkBg = Color(0xFF1A1815);
  static const Color darkSurface = Color(0xFF252220);
  static const Color darkCard = Color(0xFF2E2B27);
  static const Color darkBorder = Color(0xFF3D3830);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: darkGray,
        secondary: mediumGray,
        surface: warmWhite,
        background: cream,
        onPrimary: warmWhite,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: cream,
      textTheme: _buildTextTheme(ink, darkGray),
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: warmWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: warmWhite,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: softTan),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: softTan),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkGray, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: softTan,
        secondary: warmGray,
        surface: darkSurface,
        background: darkBg,
        onPrimary: ink,
        onSurface: softTan,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: _buildTextTheme(softTan, warmGray),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: softTan,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: softTan,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: softTan,
        foregroundColor: ink,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 48, fontWeight: FontWeight.w700, color: primary,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 36, fontWeight: FontWeight.w600, color: primary,
        letterSpacing: -1,
      ),
      headlineLarge: GoogleFonts.fraunces(
        fontSize: 28, fontWeight: FontWeight.w600, color: primary,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 22, fontWeight: FontWeight.w600, color: primary,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 18, fontWeight: FontWeight.w500, color: primary,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w600, color: primary,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w500, color: primary,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16, fontWeight: FontWeight.w400, color: primary,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w400, color: primary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w400, color: secondary,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14, fontWeight: FontWeight.w600, color: primary,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 11, fontWeight: FontWeight.w500, color: secondary,
        letterSpacing: 0.8,
      ),
    );
  }
}
