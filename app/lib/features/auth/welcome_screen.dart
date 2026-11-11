import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/auth.dart';
import 'auth_screen.dart';

/// Écran d'accueil « Compte ou Invité » — réplique du gate doux du web.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Icon(Icons.eco, color: AppColors.green, size: 44),
              const SizedBox(height: AppSpacing.s16),
              Text('Ô FORNEAU !',
                  textAlign: TextAlign.center,
                  style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep, letterSpacing: 3, fontSize: 26)),
              const SizedBox(height: 6),
              Text('PAR MAISON FORNEAU · 1974',
                  textAlign: TextAlign.center, style: AppTypography.eyebrow(AppColors.gold).copyWith(letterSpacing: 2)),
              const SizedBox(height: AppSpacing.s32),
              Text('Les recettes virales,\nréunies et adaptées.',
                  textAlign: TextAlign.center,
                  style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
              const SizedBox(height: AppSpacing.s16),
              Text('Créez un compte pour retrouver vos favoris, vos réglages et vos recettes sur tous vos appareils.',
                  textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
              const Spacer(flex: 3),
              FilledButton(
                onPressed: () => _openAuth(context, AuthMode.signup),
                child: const Text('Créer mon compte'),
              ),
              const SizedBox(height: AppSpacing.s16),
              OutlinedButton(
                onPressed: () => _openAuth(context, AuthMode.login),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: t.textTheme.titleMedium,
                ),
                child: const Text('J’ai déjà un compte'),
              ),
              const SizedBox(height: AppSpacing.s8),
              TextButton(
                onPressed: () => ref.read(guestProvider.notifier).setGuest(),
                child: Text('Continuer sans compte', style: t.textTheme.labelLarge?.copyWith(color: AppColors.muted)),
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
          ),
        ),
      ),
    );
  }

  void _openAuth(BuildContext context, AuthMode mode) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuthScreen(mode: mode)));
  }
}
