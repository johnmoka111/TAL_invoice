// views/shared/app_theme.dart
// ──────────────────────────────────────────────────────────────────────────────
// Design system de l'application — palette Indigo/Blanc, typographie, styles.
// Tous les widgets doivent utiliser ces constantes pour la cohérence visuelle.
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette de couleurs ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3949AB);       // Indigo 600
  static const Color primaryLight = Color(0xFF6F74DD);  // Indigo 300
  static const Color primaryDark = Color(0xFF00227B);   // Indigo 900
  static const Color accent = Color(0xFFFF6F00);        // Amber pour les CTA
  static const Color background = Color(0xFFF5F5F5);    // Gris très clair
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  // Statuts de facture
  static const Color statusDraft = Color(0xFF757575);   // Gris
  static const Color statusSent = Color(0xFFFF9100);    // Orange (En attente)
  static const Color statusPaid = Color(0xFF388E3C);    // Vert

  // ── Espacements ──────────────────────────────────────────────────────────────
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  // ── Bordures ─────────────────────────────────────────────────────────────────
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;

  // ── ThemeData principal ───────────────────────────────────────────────────────
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: accent,
      surface: isDark ? const Color(0xFF121212) : background,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: colorScheme.surface,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          side: isDark ? BorderSide(color: Colors.white.withAlpha(20)) : BorderSide.none,
        ),
        margin: const EdgeInsets.symmetric(
            horizontal: paddingMD, vertical: paddingSM),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          elevation: 2,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? primaryLight : primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: isDark ? primaryLight : primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
        ),
      ),

      // Input / TextField
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: paddingMD, vertical: paddingMD),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF616161)),
        floatingLabelStyle: const TextStyle(color: primary),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // BottomNavigationBar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: primaryLight,
        unselectedItemColor: isDark ? Colors.white38 : const Color(0xFF9E9E9E),
        selectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        showUnselectedLabels: true,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: primary.withAlpha(isDark ? 60 : 30),
        labelStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
      ),
    );
  }
}
