import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/auth.dart';
import 'auth_screen.dart';

/// Porte « compte ». L'invité parcourt librement les recettes ; dès qu'il veut AGIR
/// — lancer une recette, bâtir un programme, cuisiner avec son frigo — il lui faut un
/// compte, parce que ces fonctions enregistrent quelque chose qui lui appartient.
///
/// Renvoie true si l'utilisateur est connecté à la sortie.
Future<bool> exigerCompte(BuildContext context, WidgetRef ref, {String fonction = ''}) async {
  if (ref.read(currentUserProvider) != null) return true;
  if (!context.mounted) return false;
  await Navigator.of(context).push<void>(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => InvitationCompteScreen(fonction: fonction),
  ));
  return ref.read(currentUserProvider) != null;
}

/// Invitation à créer un compte, contextualisée par la fonction demandée.
/// Pas de mur : on peut toujours fermer et continuer à parcourir les recettes.
class InvitationCompteScreen extends ConsumerWidget {
  final String fonction;
  const InvitationCompteScreen({super.key, this.fonction = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, 0, margin, AppSpacing.s32),
        children: [
          Text('CRÉEZ VOTRE COMPTE', style: AppTypography.eyebrow(AppColors.gold)),
          const SizedBox(height: AppSpacing.s8),
          Text(
            fonction.isEmpty ? 'Un compte, et on cuisine' : '$fonction\ndemande un compte',
            style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Parcourir les recettes restera toujours libre. Le compte sert à garder ce qui '
            'vous appartient : vos portions, votre foyer, vos favoris, votre accès.',
            style: t.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.s24),
          _avantages(t),
          const SizedBox(height: AppSpacing.s24),
          FilledButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.signup))),
            child: const Text('Créer mon compte'),
          ),
          const SizedBox(height: AppSpacing.s8),
          TextButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.login))),
            child: Text('J’ai déjà un compte',
                style: t.textTheme.labelLarge?.copyWith(color: AppColors.green)),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text('Gratuit, en trente secondes. Vos données restent en Europe.',
              textAlign: TextAlign.center, style: t.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _avantages(ThemeData t) {
    const items = [
      (Icons.devices, 'Sur tous vos appareils', 'Vos favoris et vos réglages vous suivent.'),
      (Icons.local_offer_outlined, 'Vos mois offerts', 'Une commande Forneau ouvre l’app, jusqu’à 12 mois.'),
      (Icons.groups_outlined, 'Adapté à votre foyer', 'Les quantités et la nutrition suivent qui mange.'),
    ];
    return Column(children: [
      for (final (ic, titre, desc) in items)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle),
              child: Icon(ic, size: 19, color: AppColors.green),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titre, style: t.textTheme.titleMedium?.copyWith(color: AppColors.greenDeep)),
              Text(desc, style: t.textTheme.bodyMedium),
            ])),
          ]),
        ),
    ]);
  }
}
