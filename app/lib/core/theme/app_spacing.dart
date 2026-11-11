/// Échelle d'espacement stricte Ô Forneau ! (dp) — 4/8/16/24/32. Pas de valeur intermédiaire.
class AppSpacing {
  AppSpacing._();
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;

  /// Marge extérieure d'écran : 16 téléphone, 24 tablette (> 600 dp).
  static double screenMargin(double width) => width >= 600 ? s24 : s16;
}

/// Rayons produit : 8 (dense), 16 (cartes/modales). Jamais 0 ni > 16.
class AppRadius {
  AppRadius._();
  static const double r8 = 8;
  static const double r16 = 16;
}

/// Mouvement sobre : 160–240 ms, opacity/transform seulement.
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 240);
}

/// Cible tactile minimale partout (doigts gras/mouillés en cuisine).
const double kMinTouchTarget = 48;
