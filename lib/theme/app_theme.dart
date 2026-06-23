import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // === Core Brand Palette (Kid-Friendly) ===
  static const Color primary = Color(0xFF6C3CE1);       // Deep violet
  static const Color primaryLight = Color(0xFF8B5CF6);  // Lavender
  static const Color primaryDark = Color(0xFF4C1D95);   // Dark purple

  static const Color accent = Color(0xFFFF6B6B);        // Coral red
  static const Color accentOrange = Color(0xFFFF9F43);  // Sunny orange
  static const Color accentYellow = Color(0xFFFFD93D);  // Bright yellow
  static const Color accentMint = Color(0xFF6BCB77);    // Mint green
  static const Color accentCyan = Color(0xFF4ECDC4);    // Teal/cyan
  static const Color accentPink = Color(0xFFFF6EAB);    // Hot pink

  static const Color success = Color(0xFF6BCB77);
  static const Color warning = Color(0xFFFFD93D);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF4ECDC4);

  // === Gradients ===
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C3CE1), Color(0xFF4ECDC4)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2D0B7A), Color(0xFF6C3CE1), Color(0xFFFF6B6B)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient mathsGradient = LinearGradient(
    colors: [Color(0xFF6C3CE1), Color(0xFF8B5CF6)],
  );
  static const LinearGradient scienceGradient = LinearGradient(
    colors: [Color(0xFF4ECDC4), Color(0xFF6BCB77)],
  );
  static const LinearGradient socialGradient = LinearGradient(
    colors: [Color(0xFFFF9F43), Color(0xFFFFD93D)],
  );
  static const LinearGradient englishGradient = LinearGradient(
    colors: [Color(0xFFFF6EAB), Color(0xFFFF6B6B)],
  );
  static const LinearGradient defaultSubjectGradient = LinearGradient(
    colors: [Color(0xFF4ECDC4), Color(0xFF6C3CE1)],
  );

  // === Subject Colors ===
  static Color subjectColor(String name) {
    switch (name.toLowerCase()) {
      case 'maths': return const Color(0xFF6C3CE1);
      case 'science': return const Color(0xFF4ECDC4);
      case 'social': return const Color(0xFFFF9F43);
      case 'english': return const Color(0xFFFF6EAB);
      default: return const Color(0xFF8B5CF6);
    }
  }

  static LinearGradient subjectGradient(String name) {
    switch (name.toLowerCase()) {
      case 'maths': return mathsGradient;
      case 'science': return scienceGradient;
      case 'social': return socialGradient;
      case 'english': return englishGradient;
      default: return defaultSubjectGradient;
    }
  }

  static String subjectEmoji(String name) {
    switch (name.toLowerCase()) {
      case 'maths': return '🔢';
      case 'science': return '🔬';
      case 'social': return '🌍';
      case 'english': return '📖';
      case 'hindi': return '📝';
      case 'physics': return '⚡';
      case 'chemistry': return '🧪';
      case 'biology': return '🌿';
      default: return '✨';
    }
  }

  // === Surfaces ===
  static const Color surface = Color(0xFFF5F3FF);
  static const Color cardBg = Colors.white;
  static const Color surfaceDark = Color(0xFF12082E);
  static const Color cardDark = Color(0xFF1E1145);
  static const Color cardDark2 = Color(0xFF2A1760);

  static ThemeData get lightTheme {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    final textTheme = GoogleFonts.nunitoTextTheme().copyWith(
      displayLarge: GoogleFonts.nunito(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1),
      headlineLarge: GoogleFonts.nunito(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w500),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500),
      labelLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: const Color(0xFF1A0A3E),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A0A3E)),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1A0A3E),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w700),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: cardBg,
        shadowColor: primary.withValues(alpha: 0.1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 2.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: GoogleFonts.nunito(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
        hintStyle: GoogleFonts.nunito(color: Colors.grey.shade400),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        selectedLabelStyle: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).copyWith(
      headlineLarge: GoogleFonts.nunito(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
      titleLarge: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      titleMedium: GoogleFonts.nunito(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
      bodyMedium: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white60),
      labelLarge: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surfaceDark,
        error: error,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: cardDark,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primaryLight,
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        selectedLabelStyle: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
