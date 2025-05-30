import 'package:flutter/material.dart';

/// This class defines the overall theme configuration for both
/// light and dark modes using Flutter's ThemeData.
class ThemeConfig {

  /// LIGHT THEME CONFIGURATION
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color scheme for light mode
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF3F51B5), // Primary color (AppBar, Buttons)
        secondary: Color(0xFFB52D08), // Secondary color (Accents)
        surface: Colors.white, // Background surface
        onSurface: Color(0xFF212121), // Text color on surface
      ),

      // Text style definitions
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF212121)),
        bodyMedium: TextStyle(color: Color(0xFF212121)),
        titleMedium: TextStyle(color: Color(0xFF757575)),
      ),

      // AppBar styling
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF3F51B5), // AppBar background
        foregroundColor: Colors.white, // AppBar text/icon color
        elevation: 0,
      ),

      // Card widget styling
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ElevatedButton styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3F51B5),
          // Button background
          foregroundColor: Colors.white,
          // Text color
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),

      // FloatingActionButton styling
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),

      // Input fields (TextField, etc.) styling
      inputDecorationTheme: _inputDecorationTheme(false), // false = light theme
    );
  }

  /// DARK THEME CONFIGURATION
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,

      // Color scheme for dark mode
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB52D08), // Primary color (AppBar, Buttons)
        secondary: Color(0xFF750B0B), // Secondary color (Accents)
        surface: Color(0xFF1E1E1E), // Background surface
        onSurface: Colors.white, // Text color on surface
      ),

      // Text style definitions
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Color(0xFFB0BEC5)),
      ),

      // AppBar styling
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF750B0B), // AppBar background
        foregroundColor: Colors.white, // AppBar text/icon color
        elevation: 0,
      ),

      // Card widget styling
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ElevatedButton styling (same as light theme)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3F51B5),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),

      // FloatingActionButton styling
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFB52D08),
        foregroundColor: Colors.white,
      ),

      // Input fields (TextField, etc.) styling
      inputDecorationTheme: _inputDecorationTheme(true), // true = dark theme
    );
  }

  /// PRIVATE METHOD to generate InputDecorationTheme
  /// Accepts a boolean to switch between light and dark modes
  static InputDecorationTheme _inputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? Colors.grey[850] : Colors.grey[50],
      // Background for input fields

      // Default border with no side (flat look)
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),

      // Border when enabled but not focused
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),

      // Border when the field is focused
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF3F51B5)),
      ),
    );
  }
}
