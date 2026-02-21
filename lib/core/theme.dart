import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF6C5CE7),
    scaffoldBackgroundColor: const Color(0xFF0D0D1A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6C5CE7),
      secondary: Color(0xFF00C2FF),
      surface: Color(0xFF1E1E2E),
      onPrimary: Color(0xFFEAEAEA),
      onSecondary: Color(0xFFEAEAEA),
      onSurface: Color(0xFFEAEAEA),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFEAEAEA)),
      bodyMedium: TextStyle(color: Color(0xFFEAEAEA)),
    ),
  );
}
