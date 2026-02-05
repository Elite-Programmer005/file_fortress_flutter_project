import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // --- Centralized constants for spacing, radius, and duration ---
  static const double smallRadius = 8.0;
  static const double cardRadius = 16.0;
  static const double largeRadius = 24.0;
  static const double pagePadding = 24.0;

  static const double smallSpacing = 8.0;
  static const double standardSpacing = 16.0;
  static const double mediumSpacing = 20.0;
  static const double largeSpacing = 32.0;
  static const double extraLargeSpacing = 48.0;

  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration microAnimationDuration = Duration(milliseconds: 200);
  static const Duration transitionDuration = Duration(milliseconds: 500);

  // Light Theme Color Scheme (Material 3)
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0052D4), // Technical Blue Accent
    brightness: Brightness.light,
    background: const Color(0xFFF7F9FC),
    onBackground: const Color(0xFF1B1C1E),
    surface: const Color(0xFFFFFFFF),
    surfaceVariant: const Color(0xFFEFF2F5),
    onSurface: const Color(0xFF1B1C1E),
    onSurfaceVariant: const Color(0xFF45464F),
    primary: const Color(0xFF0052D4),
    onPrimary: const Color(0xFFFFFFFF),
    secondary: const Color(0xFF585E71),
    onSecondary: const Color(0xFFFFFFFF),
    error: const Color(0xFFBA1A1A),
    onError: const Color(0xFFFFFFFF),
    outline: const Color(0xFF757780),
    outlineVariant: const Color(0xFFC5C6D0),
  );

  // Dark Theme Color Scheme (Material 3)
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF5A9BFF), // A brighter blue for dark mode
    brightness: Brightness.dark,
    background: const Color(0xFF121418),
    onBackground: const Color(0xFFE2E2E6),
    surface: const Color(0xFF1B1D21),
    surfaceVariant: const Color(0xFF2F3238),
    onSurface: const Color(0xFFE2E2E6),
    onSurfaceVariant: const Color(0xFFC5C6D0),
    primary: const Color(0xFF5A9BFF),
    onPrimary: const Color(0xFF002B75),
    secondary: const Color(0xFFBFC6DC),
    onSecondary: const Color(0xFF2A3042),
    error: const Color(0xFFFFB4AB),
    onError: const Color(0xFF690005),
    outline: const Color(0xFF8F9199),
    outlineVariant: const Color(0xFF44474E),
  );

  // --- Typography ---
  static final TextStyle displayMedium =
      const TextStyle(fontSize: 45, fontWeight: FontWeight.w400);
  static final TextStyle headlineLarge =
      const TextStyle(fontSize: 32, fontWeight: FontWeight.w700);
  static final TextStyle headlineMedium =
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w600);
  static final TextStyle headlineSmall =
      const TextStyle(fontSize: 24, fontWeight: FontWeight.w400);
  static final TextStyle titleMedium =
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500);
  static final TextStyle bodyLarge =
      const TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static final TextStyle bodyMedium =
      const TextStyle(fontSize: 14, fontWeight: FontWeight.w400);
  static final TextStyle bodySmall =
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w400);
  static final TextStyle labelMedium =
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w500);

  // --- Base Theme Data ---
  static ThemeData _baseTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: colorScheme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: colorScheme.background,
          systemNavigationBarIconBrightness:
              colorScheme.brightness == Brightness.dark
                  ? Brightness.light
                  : Brightness.dark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.3)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius)),
        ),
      ),
    );
  }

  // --- Public Theme Accessors ---
  static ThemeData get lightTheme => _baseTheme(_lightColorScheme);
  static ThemeData get darkTheme => _baseTheme(_darkColorScheme);
}
