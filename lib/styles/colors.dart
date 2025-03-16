import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color gradientStart = Color(0xFFffa428); // top left
  static const Color gradientEnd = Color(0xFF9c3936);   // bottom right

  // Create a linear gradient
  static const Gradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      gradientStart,
      gradientEnd,
    ],
  );
}
