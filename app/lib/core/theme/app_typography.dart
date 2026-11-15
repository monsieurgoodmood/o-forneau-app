import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typo Ô Forneau ! — titres Playfair Display (éditorial, comme le web), corps Inter.
///
/// Les polices sont **embarquées** (`assets/fonts/`, déclarées dans `pubspec.yaml`), plus
/// téléchargées depuis fonts.gstatic.com au lancement comme le faisait `google_fonts`.
/// Deux raisons, dans cet ordre :
///
/// 1. Chaque premier lancement envoyait l'adresse IP de l'utilisateur à Google, sans
///    consentement et sans que rien dans l'app ne le laisse voir. C'est précisément ce que
///    le tribunal de Munich a jugé illicite en janvier 2022 pour un site web, et l'app n'a
///    aucune raison d'en prendre le risque pour une police.
/// 2. L'app est hors-ligne d'abord. Télécharger la typo au lancement contredit cette
///    promesse : sans réseau, les titres tombaient dans une police de secours.
///
/// Instances statiques sous-ensemblées au latin étendu — les sept langues du catalogue et
/// rien de plus : 428 Ko embarqués contre 1,18 Mo de variable téléchargée.
class AppTypography {
  AppTypography._();

  static const titres = 'Playfair Display';
  static const corps = 'Inter';

  static TextTheme textTheme(Color ink, Color muted) => const TextTheme().copyWith(
        displayLarge: _titre(34, ink, hauteur: 1.12),
        displaySmall: _titre(28, ink, hauteur: 1.15),
        headlineMedium: _titre(24, ink),
        headlineSmall: _titre(21, ink, hauteur: 1.2),
        titleLarge: _titre(20, ink),
        titleMedium: _corps(17, FontWeight.w600, ink),
        bodyLarge: _corps(16, FontWeight.w400, ink, hauteur: 1.5),
        bodyMedium: _corps(14, FontWeight.w400, muted, hauteur: 1.45),
        labelLarge: _corps(14, FontWeight.w600, ink),
        labelMedium: _corps(13, FontWeight.w600, ink),
        labelSmall: _corps(12, FontWeight.w500, muted),
      );

  /// Eyebrow doré en petites capitales espacées (VÉGÉTALE, USTENSILE FORNEAU).
  ///
  /// Par défaut l'or LISIBLE : en petites capitales de 12 px, c'est du texte courant, donc
  /// le seuil est 4,5:1. L'or de surface n'y arrivait pas (2,93:1 sur le vert pâle).
  static TextStyle eyebrow([Color couleur = AppColors.goldText]) =>
      _corps(12, FontWeight.w700, couleur, espacement: 1.1);

  /// Mode cuisine : étape ≥ 20 sp, lisible à bout de bras.
  static TextStyle cookStep(Color ink) => _corps(22, FontWeight.w500, ink, hauteur: 1.5);

  static TextStyle _titre(double taille, Color couleur, {double? hauteur}) => TextStyle(
        fontFamily: titres,
        fontSize: taille,
        fontWeight: FontWeight.w700,
        color: couleur,
        height: hauteur,
      );

  static TextStyle _corps(double taille, FontWeight graisse, Color couleur,
          {double? hauteur, double? espacement}) =>
      TextStyle(
        fontFamily: corps,
        fontSize: taille,
        fontWeight: graisse,
        color: couleur,
        height: hauteur,
        letterSpacing: espacement,
      );
}
