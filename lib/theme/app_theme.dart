import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryRed = Color(0xFFE94057);
  static const Color primaryYellow = Color(0xFFF27121);
  
  // Button color
  static const Color buttonColor = Color(0xFF8A2D38);
  
  // Text colors
  static const Color textLight = Colors.white;
  static const Color textDark = Color(0xFF333333);
  
  // Input field colors
  static const Color inputFieldLight = Color(0xFFedf0f8);
  static const Color inputFieldDark = Color(0xFF2A2A2A);
  
  // Define theme data
  static ThemeData lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryRed,
      colorScheme: ColorScheme.light(
        primary: primaryRed,
        secondary: primaryYellow,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryRed,
      colorScheme: ColorScheme.dark(
        primary: primaryRed,
        secondary: primaryYellow,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textLight),
        bodyMedium: TextStyle(color: textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
        ),
      ),
    );
  }
}