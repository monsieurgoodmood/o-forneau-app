import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart' show AppRadius;
import 'app_typography.dart';

/// ThemeData Ô Forneau ! — identité crème/vert/or, CLAIR uniquement (charte : pas de sombre).
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = AppColors.lightScheme;
    final text = AppTypography.textTheme(scheme.onSurface, scheme.onSurfaceVariant);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: text,
      splashFactory: InkRipple.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: const Color(0xFFF6F3EC),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: text.titleMedium,
        ),
      ),
    );
  }

  /// Pas de mode sombre : on renvoie le thème clair (main force ThemeMode.light).
  static ThemeData get dark => light;
}
