import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typo Ô Forneau ! — titres Playfair Display (éditorial, comme le web), corps Inter.
class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Color ink, Color muted) => TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(fontSize: 34, fontWeight: FontWeight.w700, color: ink, height: 1.12),
        displaySmall: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: ink, height: 1.15),
        headlineMedium: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700, color: ink),
        headlineSmall: GoogleFonts.playfairDisplay(fontSize: 21, fontWeight: FontWeight.w700, color: ink, height: 1.2),
        titleLarge: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink),
        titleMedium: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: ink),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: ink, height: 1.5),
        bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: muted, height: 1.45),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: ink),
        labelMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ink),
        labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
      );

  /// Eyebrow doré en petites capitales espacées (VÉGÉTALE, USTENSILE FORNEAU).
  static TextStyle eyebrow(Color gold) => GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w700, color: gold, letterSpacing: 1.1);

  /// Mode cuisine : étape ≥ 20 sp, lisible à bout de bras.
  static TextStyle cookStep(Color ink) =>
      GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w500, color: ink, height: 1.5);
}
