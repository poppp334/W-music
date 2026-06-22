import 'package:flutter/material.dart';

/// "Sonic Dark" design system — dark glassmorphism palette with soft lavender accent.
class WTheme {
  // ─── Color Tokens ────────────────────────────────────────────────────

  static const Color background = Color(0xFF0E0E12);
  static const Color surface = Color(0xFF15151A);
  static const Color surfaceVariant = Color(0xFF1E1E26);
  static const Color card = Color(0xFF1A1A22);
  static const Color accent = Color(0xFFB8A4F5);
  static const Color accentLight = Color(0xFFD4C9FC);
  static const Color onBackground = Color(0xFFEDEDF2);
  static const Color onSurface = Color(0xFFEDEDF2);
  static const Color onSurfaceVariant = Color(0x99EDEDF2);
  static const Color disabled = Color(0xFF3A3A44);
  static const Color error = Color(0xFFcf6679);

  // Dark glassmorphism surface tokens
  static const Color glassSurface = Color(0x33FFFFFF);
  static const Color glassSurfaceStrong = Color(0x4DFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);

  // ─── Typography ───────────────────────────────────────────────────────

  static const String _fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: onBackground,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: onBackground,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: onBackground,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: onBackground,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: onBackground,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: onBackground,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: onSurface,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: onSurface,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: onSurfaceVariant,
  );

  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: onBackground,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: onSurfaceVariant,
  );

  // ─── Shape ────────────────────────────────────────────────────────────

  static const double cardRadius = 12.0;
  static const double chipRadius = 20.0;
  static const double buttonRadius = 8.0;

  // ─── Spacing ──────────────────────────────────────────────────────────

  static const double gutter = 16.0;
  static const double sectionMargin = 32.0;
  static const double touchTarget = 48.0;

  // ─── Theme Data ───────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          onPrimary: Colors.black,
          secondary: accentLight,
          onSecondary: Colors.black,
          surface: surface,
          onSurface: onSurface,
          error: error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: background,
        cardColor: card,
        dividerColor: surfaceVariant,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: displayMedium,
          iconTheme: IconThemeData(color: onBackground, size: 24),
        ),
        cardTheme: CardThemeData(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceVariant,
          labelStyle: labelLarge.copyWith(color: onSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(chipRadius),
          ),
          side: BorderSide.none,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: accent,
          inactiveTrackColor: disabled,
          thumbColor: accent,
          overlayColor: accent.withValues(alpha: 0.12),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        iconTheme: const IconThemeData(
          color: onSurface,
          size: 24,
        ),
        textTheme: const TextTheme(
          displayLarge: displayLarge,
          displayMedium: displayMedium,
          headlineMedium: headlineMedium,
          titleLarge: titleLarge,
          titleMedium: titleMedium,
          titleSmall: titleSmall,
          bodyLarge: bodyLarge,
          bodyMedium: bodyMedium,
          bodySmall: bodySmall,
          labelLarge: labelLarge,
          labelSmall: labelSmall,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
        ),
      );
}
