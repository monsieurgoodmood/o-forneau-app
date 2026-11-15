import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/mesure.dart';
import '../../l10n/app_localizations.dart';

/// Demande de consentement à la mesure d'usage.
///
/// Trois partis pris, et chacun a une raison :
///
/// 1. **Elle ne s'affiche pas au premier écran.** On laisse voir l'app d'abord. Une
///    demande posée avant que la personne ait vu ce qu'elle gagne n'est pas un choix
///    éclairé, c'est un péage.
/// 2. **Refuser coûte exactement un clic, comme accepter**, et les deux boutons ont le
///    même poids visuel. Une fenêtre où « Accepter » est un bouton plein et « Refuser »
///    un lien gris est un dark pattern — et c'est précisément ce que la CNIL sanctionne.
/// 3. **Elle ne peut pas être esquivée sans répondre.** Pas de croix, pas de fermeture en
///    tapant à côté : une fenêtre qu'on ferme sans répondre laisse un état indécis qu'on
///    finirait par interpréter, et l'interpréter voudrait dire décider à la place des gens.
class ConsentementMesure extends ConsumerWidget {
  const ConsentementMesure({super.key});

  /// Pose la question si elle n'a jamais reçu de réponse (ou si la réponse a six mois).
  static Future<void> demanderSiBesoin(BuildContext context, WidgetRef ref) async {
    final m = ref.read(mesureProvider);
    if (m.consentement != null) return;
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ConsentementMesure(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final m = ref.read(mesureProvider);

    Future<void> repondre(bool oui) async {
      await m.repondre(oui);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(L.of(context).mesureEnregistre)));
    }

    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r16)),
      title: Text(L.of(context).mesureTitre,
          style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
      content: Text(L.of(context).mesureTexte, style: t.textTheme.bodyMedium),
      actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s16),
      actions: [
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => repondre(false),
              style: _pastille,
              child: Text(L.of(context).mesureRefuser),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: FilledButton(
              onPressed: () => repondre(true),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
              child: Text(L.of(context).mesureAccepter),
            ),
          ),
        ]),
      ],
    );
  }

  static final _pastille = OutlinedButton.styleFrom(
    foregroundColor: AppColors.green,
    side: const BorderSide(color: AppColors.green),
    minimumSize: const Size(0, 48),
    shape: const StadiumBorder(),
  );
}
