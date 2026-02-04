import 'package:flutter/material.dart';

/// Carmen's Garden Cafe brand colors
/// Based on the official color palette from prompts guide
class CarmenColors {
  CarmenColors._();

  // Primary Colors
  static const Color primaryGreen = Color(0xFF3b5006);   // Dark Forest Green - App bar, main buttons
  static const Color primaryLime = Color(0xFFa8bd06);    // Lime Green - Highlights, secondary buttons
  static const Color accentYellow = Color(0xFFe7e80e);   // Bright Yellow - Warnings, success states
  
  // Neutral Colors
  static const Color lightCream = Color(0xFFf8f7f0);     // Off-white background
  static const Color darkBrown = Color(0xFF272007);      // Text color
  static const Color olive = Color(0xFF65551c);          // Secondary brown
  
  // Semantic Colors
  static const Color errorRed = Color(0xFFd32f2f);       // Error states
  static const Color successGreen = Color(0xFF4CAF50);   // Success states
  static const Color warningOrange = Color(0xFFFF9800);  // Warning states
  
  // Order Status Colors
  static const Color statusPending = Color(0xFFFF9800);    // Orange
  static const Color statusPreparing = Color(0xFF2196F3); // Blue
  static const Color statusReady = Color(0xFF4CAF50);     // Green
  static const Color statusCompleted = Color(0xFF9E9E9E); // Grey
  static const Color statusCancelled = Color(0xFFd32f2f); // Red
  
  // Surface Colors
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color divider = Color(0xFFE0E0E0);
}
