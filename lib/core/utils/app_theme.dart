//  (-_•) :pistola:
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- COLOR SCHEMES
const ColorScheme myLightColorScheme = ColorScheme.light(
  primary: Color(0xFF009688),
  secondary: Color(0xFF80CBC4),
  tertiary: Color(0xFF004D40),
  surface: Colors.white,
  onPrimary: Colors.white,
  onSecondary: Colors.black,
  onTertiary: Colors.white,
  onSurface: Colors.black,
);

const ColorScheme myDarkColorScheme = ColorScheme.dark(
  primary: Color(0xFF6A1B9A),
  secondary: Color(0xFF9C27B0),
  tertiary: Color(0xFF7E57C2),
  surface: Color(0xFF212121),
  onPrimary: Colors.white,
  onSecondary: Colors.white,
  onTertiary: Colors.white,
  onSurface: Colors.white,
);

// --- PRIMARY SWATCH
const MaterialColor mySwatch = MaterialColor(0xFF6A1B9A, {
  50: Color(0xFFF1E1F4),
  100: Color(0xFFD5A6D4),
  200: Color(0xFFB16CB4),
  300: Color(0xFF9C4F94),
  400: Color(0xFF7F2A74),
  500: Color(0xFF6A1B9A),
  600: Color(0xFF571782),
  700: Color(0xFF46156A),
  800: Color(0xFF3B1052),
  900: Color(0xFF2A0842),
});

// --- TEXT THEME
final TextTheme myTextTheme = TextTheme(
  displayLarge: GoogleFonts.montserrat(
    fontSize: 72,
    fontWeight: FontWeight.bold,
  ),
  displayMedium: GoogleFonts.montserrat(
    fontSize: 36,
    fontWeight: FontWeight.bold,
  ),
  displaySmall: GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  ),
  headlineLarge: GoogleFonts.montserrat(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  ),
  headlineMedium: GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  ),
  headlineSmall: GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  ),
  titleLarge: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold),
  titleMedium: GoogleFonts.montserrat(
    fontSize: 18,
    fontWeight: FontWeight.w500,
  ),
  titleSmall: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
  bodyLarge: GoogleFonts.openSans(fontSize: 16),
  bodyMedium: GoogleFonts.openSans(fontSize: 14),
  bodySmall: GoogleFonts.openSans(fontSize: 12),
  labelLarge: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600),
  labelMedium: GoogleFonts.openSans(fontSize: 12, fontWeight: FontWeight.w500),
  labelSmall: GoogleFonts.openSans(fontSize: 11, fontWeight: FontWeight.w500),
);

// --- FUNCTION TO GENERATE THEME
ThemeData getAppTheme(ColorScheme colorScheme) {
  return ThemeData(
    primarySwatch: mySwatch,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      titleTextStyle: myTextTheme.headlineSmall?.copyWith(
        color: colorScheme.onPrimary,
      ),
      iconTheme: IconThemeData(color: colorScheme.secondary),
      actionsIconTheme: IconThemeData(color: colorScheme.secondary),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.primary,
      selectedItemColor: colorScheme.tertiary,
      unselectedItemColor: colorScheme.onPrimary.withValues(alpha: 0.5),
      selectedLabelStyle: myTextTheme.bodyMedium,
      unselectedLabelStyle: myTextTheme.bodyMedium,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(colorScheme.secondary),
        foregroundColor: WidgetStateProperty.all(colorScheme.onSecondary),
        textStyle: WidgetStateProperty.all(myTextTheme.titleSmall),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.all(colorScheme.onPrimary),
        textStyle: WidgetStateProperty.all(myTextTheme.headlineSmall),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(colorScheme.secondary),
        textStyle: WidgetStateProperty.all(myTextTheme.displaySmall),
      ),
    ),
    textTheme: myTextTheme,
    fontFamily: GoogleFonts.montserrat().fontFamily,
    scaffoldBackgroundColor: colorScheme.surface,
    useMaterial3: true,
  );
}
