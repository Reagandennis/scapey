import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color background = Color(0xFF0D0D1A);
  static const Color primary = Color(0xFF6C5CE7);
  static const Color accent = Color(0xFF00C2FF);
  static const Color text = Color(0xFFEAEAEA);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: Color(0xFF1E1E2E),
      onPrimary: text,
      onSecondary: text,
      onSurface: text,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: text),
      bodyMedium: TextStyle(color: text),
      titleLarge: TextStyle(color: text, fontWeight: FontWeight.bold),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: text),
      titleTextStyle: TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: text,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.grey),
      hintStyle: const TextStyle(color: Colors.grey),
    ),
  );
}
