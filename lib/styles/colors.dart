import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color gradientStart = Color(0xFFffa428); // top left
  static const Color gradientEnd = Color(0xFF9c3936);   // bottom right

  // Text colors
  static const Color titleText = Color(0xFFf6e29b);     // Gold text for title and links
  static const Color titleShadow = Color(0xFF4a3414);   // Brown shadow

  // Input and button gradient colors
  static const Color inputGradientStart = Color(0xFFfbf477);  // Light yellow
  static const Color inputGradientEnd = Color(0xFFfe7e48);    // Orange

  // Border radius
  static final BorderRadius pillShape = BorderRadius.circular(25.0);

  // Gradients
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

  // Input fields gradient (more yellow and more diagonal)
  static const Gradient inputGradient = LinearGradient(
    begin: Alignment(-2.0, -2.0),
    end: Alignment(1.0, 1.0),
    colors: [
      inputGradientStart,
      inputGradientStart,  // Added another yellow stop
      inputGradientEnd,
    ],
    stops: [0.0, 0.4, 1.0],  // Adjusted from 0.5 to 0.4 to show more orange
  );

  // Button gradient (more orange)
  static const Gradient buttonGradient = LinearGradient(
    begin: Alignment(-2.0, -2.0),
    end: Alignment(2.0, 2.0),
    colors: [
      inputGradientStart,
      inputGradientEnd,
      inputGradientEnd,
    ],
    stops: [0.0, 0.3, 1.0],
  );

  // Input decoration theme
  static final InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: Colors.transparent,
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

  // Button style with gradient
  static final ButtonStyle pillButtonStyle = ElevatedButton.styleFrom(
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: pillShape,
    ),
    elevation: 0,
  );
}
