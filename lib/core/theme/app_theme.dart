import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo-500
  static const Color accentColor = Color(0xFF10B981);  // Emerald-500
  static const Color warningColor = Color(0xFFF59E0B); // Amber-500
  static const Color errorColor = Color(0xFFEF4444);   // Red-500

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0F172A);      // Slate-900
  static const Color darkSurface = Color(0xFF1E293B); // Slate-800
  static const Color darkText = Color(0xFFF8FAFC);    // Slate-50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate-400

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8FAFC);    // Slate-50
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF0F172A);  // Slate-900
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate-500

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
          surface: darkSurface,
          onSurface: darkText,
          error: errorColor,
        ),
        cardTheme: CardThemeData(
          color: darkSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(color: darkText, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.outfit(color: darkText, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.outfit(color: darkText, fontWeight: FontWeight.w600),
        ),
      );

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: lightBg,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          surface: lightSurface,
          onSurface: lightText,
          error: errorColor,
        ),
        cardTheme: CardThemeData(
          color: lightSurface,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(color: lightText, fontWeight: FontWeight.bold),
          displayMedium: GoogleFonts.outfit(color: lightText, fontWeight: FontWeight.bold),
          titleLarge: GoogleFonts.outfit(color: lightText, fontWeight: FontWeight.w600),
        ),
      );
}

// Custom extension for Glassmorphism and other design tokens
extension AppThemeExtension on ThemeData {
  Color get glassColor => brightness == Brightness.dark
      ? Colors.white.withOpacity(0.05)
      : Colors.white.withOpacity(0.7);
  
  Color get glassBorder => brightness == Brightness.dark
      ? Colors.white.withOpacity(0.1)
      : Colors.black.withOpacity(0.05);

  double get sidebarWidth => 260.0;
  double get collapsedSidebarWidth => 80.0;
}
