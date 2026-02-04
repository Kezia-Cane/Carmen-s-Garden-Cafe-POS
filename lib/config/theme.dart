import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Custom page transition that has NO animation (instant transition)
/// for maximum performance on low-spec devices
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Return child directly - no animation wrapper
    return child;
  }
}

/// Carmen's Garden Cafe App Theme
/// Optimized for OUKITEL WP18 (MediaTek Helio A22, 4GB RAM)
/// PERFORMANCE PRIORITY: All animations disabled
class CarmenTheme {
  CarmenTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: CarmenColors.primaryGreen,
        secondary: CarmenColors.primaryLime,
        tertiary: CarmenColors.accentYellow,
        surface: CarmenColors.surface,
        error: CarmenColors.errorRed,
        onPrimary: Colors.white,
        onSecondary: CarmenColors.darkBrown,
        onSurface: CarmenColors.darkBrown,
        onError: Colors.white,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: CarmenColors.lightCream,
      
      // PERFORMANCE: Disable all splash/ripple effects
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      
      // PERFORMANCE: Disable all page transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoTransitionBuilder(),
          TargetPlatform.iOS: _NoTransitionBuilder(),
          TargetPlatform.windows: _NoTransitionBuilder(),
        },
      ),
      
      // App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: CarmenColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: CarmenColors.primaryGreen,
        unselectedItemColor: CarmenColors.olive,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 12,
        ),
      ),
      
      // Elevated Button (Primary action buttons)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CarmenColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Epilogue',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined Button (Secondary actions)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CarmenColors.primaryGreen,
          side: const BorderSide(color: CarmenColors.primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Epilogue',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: CarmenColors.primaryGreen,
          textStyle: const TextStyle(
            fontFamily: 'Epilogue',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Cards
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CarmenColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CarmenColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CarmenColors.primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CarmenColors.errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          fontFamily: 'Epilogue',
          color: CarmenColors.olive.withOpacity(0.6),
        ),
      ),
      
      // Chips (for filters)
      chipTheme: ChipThemeData(
        backgroundColor: CarmenColors.surfaceVariant,
        selectedColor: CarmenColors.primaryLime,
        labelStyle: const TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CarmenColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CarmenColors.darkBrown,
        ),
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: CarmenColors.darkBrown,
        contentTextStyle: const TextStyle(
          fontFamily: 'Epilogue',
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: CarmenColors.divider,
        thickness: 1,
        space: 1,
      ),
      
      // Typography
      textTheme: const TextTheme(
        // Display
        displayLarge: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: CarmenColors.darkBrown,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: CarmenColors.darkBrown,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: CarmenColors.darkBrown,
        ),
        // Headlines
        headlineLarge: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: CarmenColors.darkBrown,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: CarmenColors.darkBrown,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: CarmenColors.darkBrown,
        ),
        // Titles
        titleLarge: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: CarmenColors.darkBrown,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CarmenColors.darkBrown,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CarmenColors.darkBrown,
        ),
        // Body
        bodyLarge: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: CarmenColors.darkBrown,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: CarmenColors.darkBrown,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: CarmenColors.olive,
        ),
        // Labels
        labelLarge: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: CarmenColors.darkBrown,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: CarmenColors.darkBrown,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Epilogue',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: CarmenColors.olive,
        ),
      ),
    );
  }
}
