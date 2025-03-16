import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color gradientStart = Color(0xFFffa428); // top left
  static const Color gradientEnd = Color(0xFF9c3936);   // bottom right

  // Text colors
  static const Color titleText = Color(0xFFf6e29b);     // Gold text
  static const Color titleShadow = Color(0xFF4a3414);   // Brown shadow

  // Create a linear gradient
  static const Gradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradientStart,
      gradientEnd,
      gradientEnd,  // Added another instance of gradientEnd
    ],
    stops: [0.0, 0.5, 1.0],  // Adjust these values to control the color distribution
  );
}
