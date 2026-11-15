import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/notifications.dart';
import '../../l10n/app_localizations.dart';

/// Demande d'activation des notifications.
///
/// Mêmes principes que la demande de mesure, et une contrainte de plus : la boîte système
/// d'Android ne peut être montrée qu'un nombre limité de fois avant d'être bloquée pour de
/// bon. On ne la gaspille donc pas au premier lancement — on pose d'abord NOTRE question,
/// à partir de la deuxième session, et seul un oui déclenche la demande système.
class ConsentementNotifications extends ConsumerWidget {
  const ConsentementNotifications({super.key});

  static Future<void> demanderSiBesoin(BuildContext context, WidgetRef ref) async {
    final n = ref.read(notificationsProvider);
    if (!n.aDemander) return;
    await Future<void>.delayed(const Duration(seconds: 6));
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ConsentementNotifications(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final n = ref.read(notificationsProvider);

    Future<void> repondre(bool oui) async {
      final ok = await n.repondre(oui);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(oui && !ok ? L.of(context).notifRefuseeSysteme : L.of(context).notifEnregistre)));
    }

    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r16)),
      title: Text(L.of(context).notifTitre,
          style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
      content: Text(L.of(context).notifTexte, style: t.textTheme.bodyMedium),
      actionsPadding: const EdgeInsets.fromLTRB(AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s16),
      actions: [
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => repondre(false),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  minimumSize: const Size(0, 48),
                  shape: const StadiumBorder()),
              child: Text(L.of(context).notifRefuser),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: FilledButton(
              onPressed: () => repondre(true),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
              child: Text(L.of(context).notifAccepter),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Bloc « Notifications » de l'écran Compte : interrupteur général et catégories.
class ReglagesNotifications extends ConsumerStatefulWidget {
  const ReglagesNotifications({super.key});
  @override
  ConsumerState<ReglagesNotifications> createState() => _ReglagesNotificationsState();
}

class _ReglagesNotificationsState extends ConsumerState<ReglagesNotifications> {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final n = ref.read(notificationsProvider);
    if (!Notifications.disponible) return const SizedBox.shrink();
    final actives = n.choix == true;
    final cats = n.categories;
    final libelles = {
      'soir': L.of(context).notifCatSoir,
      'perso': L.of(context).notifCatPerso,
      'nouveautes': L.of(context).notifCatNouveautes,
      'acces': L.of(context).notifCatAcces,
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s8, AppSpacing.s8),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(AppRadius.r16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(L.of(context).notifSection, style: t.textTheme.titleMedium?.copyWith(color: AppColors.greenDeep)),
          subtitle: Text(L.of(context).notifSectionTexte, style: t.textTheme.bodySmall),
          value: actives,
          activeColor: AppColors.green,
          onChanged: (v) async {
            if (v) {
              final ok = await n.repondre(true);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.of(context).notifRefuseeSysteme)));
              }
            } else {
              await n.desactiver();
            }
            if (mounted) setState(() {});
          },
        ),
        if (actives)
          for (final e in libelles.entries)
            CheckboxListTile(
              contentPadding: const EdgeInsets.only(left: AppSpacing.s8),
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.green,
              title: Text(e.value, style: t.textTheme.bodyMedium),
              value: cats[e.key] ?? true,
              onChanged: (v) async {
                await n.reglerCategorie(e.key, v ?? true);
                if (mounted) setState(() {});
              },
            ),
      ]),
    );
  }
}
