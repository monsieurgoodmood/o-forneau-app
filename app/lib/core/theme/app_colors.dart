import 'package:flutter/material.dart';

/// Jetons couleur Ô Forneau ! — identité réelle forneau.com, répliquée du web.
/// Crème / vert forêt / or. Thème CLAIR uniquement (jamais de sombre : charte).
class AppColors {
  AppColors._();

  // Fonds crème
  static const cream = Color(0xFFF3F1EB); // fond d'écran
  static const creamTop = Color(0xFFECEAE4); // barre du haut
  static const cardBg = Color(0xFFFDFCF8); // corps des cartes
  static const white = Color(0xFFFFFFFF); // recherche, pastilles

  // Vert forêt
  static const green = Color(0xFF2D4A2B); // primaire (boutons, états actifs)
  static const greenDeep = Color(0xFF243F20); // titres
  static const greenSoft = Color(0xFFE3EDDE); // conteneurs doux (n° d'étape, astuce)

  // Or
  static const gold = Color(0xFFA9823E); // eyebrows, icônes
  static const goldDeep = Color(0xFFB98E46);

  // Encre / neutres
  static const ink = Color(0xFF2A2008);
  static const muted = Color(0xFF5E6157);
  static const line = Color(0xFFD8D0BE);

  static const danger = Color(0xFFC0392B);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: green,
    onPrimary: Color(0xFFF6F3EC),
    primaryContainer: greenSoft,
    onPrimaryContainer: greenDeep,
    secondary: gold,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF1E6D4),
    onSecondaryContainer: Color(0xFF5A4318),
    error: danger,
    onError: Color(0xFFFFFFFF),
    surface: cardBg,
    onSurface: ink,
    surfaceContainerHighest: white,
    onSurfaceVariant: muted,
    outline: line,
  );
}
