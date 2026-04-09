import 'package:flutter/material.dart';

class AppTheme {
  // =========================================================
  // ☀️ LIGHT THEME DICTIONARY
  // Inherited from the legacy AppColors class
  // =========================================================
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF4F6F9), // Legacy: AppColors.background

    colorScheme: const ColorScheme.light(
      // Brand Colors
      primary: Color(0xFF5A8DF3),          // Legacy: AppColors.primary
      secondary: Color(0xFF4A90E2),        // Legacy: AppColors.primaryBlue

      // Background & Surface Colors
      // Note: 'background' is deprecated, scaffoldBackgroundColor handles the main background.
      surface: Colors.white,               // Legacy: AppColors.taskCardBg / white
      surfaceContainerHighest: Color(0xFFE0F7FA), // Legacy: AppColors.backgroundBlue (Tinted background)

      // Text Colors
      onSurface: Color(0xFF2D3440),        // Legacy: AppColors.textDark
      onSurfaceVariant: Color(0xFF757575), // Legacy: AppColors.grayText / textSecondary

      // Border & Status Colors
      outline: Color(0xFFE2E8F0),          // Legacy: AppColors.border
      error: Colors.redAccent,             // Legacy: AppColors.error
      tertiary: Colors.green,              // Using Tertiary for Success (Green)
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF5A8DF3)),
      titleTextStyle: TextStyle(
        color: Color(0xFF5A8DF3),
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    ),

    dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0)),
  );

  // =========================================================
  // 🌙 DARK THEME DICTIONARY
  // Extracted from the provided Stitch Design System
  // =========================================================
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F172A), // Neutral Slate Dark

    colorScheme: const ColorScheme.dark(
      // Brand Colors (Slightly brighter to stand out on dark background)
      primary: Color(0xFF60A5FA),          // Bright Blue
      secondary: Color(0xFF61789A),        // Slate Blue

      // Background & Surface Colors
      // Note: 'background' is deprecated, scaffoldBackgroundColor handles the main background.
      surface: Color(0xFF1E293B),          // Slightly lighter than background, used for Cards
      surfaceContainerHighest: Color(0xFF162032), // Dark mode counterpart for backgroundBlue

      // Text Colors
      onSurface: Colors.white,             // Primary text (White)
      onSurfaceVariant: Color(0xFF94A3B8), // Secondary text (Light Slate)

      // Border, Status & Highlight Colors
      outline: Color(0xFF334155),          // Faint Card Border
      error: Color(0xFFF87171),            // Pinkish Red (Similar to Trash Icon)
      tertiary: Color(0xFFD19900),         // Mustard Yellow (Similar to Edit Pencil Icon)
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF60A5FA)),
      titleTextStyle: TextStyle(
        color: Color(0xFF60A5FA),
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    ),

    dividerTheme: const DividerThemeData(color: Color(0xFF334155)),
  );
}