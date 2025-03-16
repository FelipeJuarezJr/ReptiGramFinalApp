import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color gradientStart = Color(0xFFffa428); // top left
  static const Color gradientEnd = Color(0xFF9c3936);   // bottom right

  // Text colors
  static const Color titleText = Color(0xFFf6e29b);     // Gold text for title and links
  static const Color titleShadow = Color(0xFF4a3414);   // Brown shadow

  // Border radius
  static final BorderRadius pillShape = BorderRadius.circular(25.0);

  // Input decoration theme
  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: pillShape,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: pillShape,
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: pillShape,
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: pillShape,
      borderSide: BorderSide.none,
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: pillShape,
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  );

  // Create a linear gradient
  static const Gradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradientStart,
      gradientEnd,
      gradientEnd,
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Button style
  static final ButtonStyle pillButtonStyle = ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: pillShape,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  );
}
