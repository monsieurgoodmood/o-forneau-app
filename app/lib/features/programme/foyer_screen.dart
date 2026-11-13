import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/programme.dart';
import 'programme_widgets.dart';
import '../../l10n/app_localizations.dart';

/// Mon foyer — réplique du web : solo/plusieurs, nombre de personnes, profil et régime par membre.
class FoyerScreen extends ConsumerWidget {
  const FoyerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final foyer = ref.watch(foyerProvider);
    final set = ref.read(foyerProvider.notifier).set;
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);
    final solo = foyer.mode == 'solo';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        title: Text(L.of(context).monFoyer, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
        children: [
          Eyebrow(L.of(context).monFoyer),
          Text(L.of(context).pourQuiCuisinezVous, style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
          const SizedBox(height: AppSpacing.s8),
          Text(L.of(context).onAdapteLesQuantitesDesRecettes,
              style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.s24),

          Eyebrow(L.of(context).jeCuisine),
          SegPair(
            a: L.of(context).justePourMoi, subA: '1 personne', b: L.of(context).pourPlusieurs, subB: 'famille, amis…',
            first: solo,
            onChanged: (s) => set(foyer.copyWith(mode: s ? 'solo' : 'famille')),
          ),
          if (!solo) ...[
            const SizedBox(height: AppSpacing.s24),
            Eyebrow(L.of(context).combienDePersonnes),
            CounterCard(value: foyer.count.clamp(1, 12), label: 'personnes', onChanged: (v) => set(foyer.copyWith(count: v))),
            const SizedBox(height: AppSpacing.s24),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(AppRadius.r16),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                const Icon(Icons.adjust, color: AppColors.gold),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: RichText(
                    text: TextSpan(style: t.textTheme.bodyLarge, children: [
                      TextSpan(text: L.of(context).affinerLaNutrition, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep, fontSize: 18)),
                      TextSpan(text: L.of(context).renseignezAgeTaillePoidsActiviteEt),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.s24),
            for (var i = 0; i < foyer.members.length; i++) ...[
              _MemberCard(
                index: i,
                member: foyer.members[i],
                onChanged: (m) {
                  final list = List<Member>.from(foyer.members);
                  list[i] = m;
                  set(foyer.copyWith(members: list));
                },
              ),
              const SizedBox(height: AppSpacing.s16),
            ],
          ],
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final int index;
  final Member member;
  final ValueChanged<Member> onChanged;
  const _MemberCard({required this.index, required this.member, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final m = member;
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, color: AppColors.green, size: 20),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(child: Text('Personne ${index + 1}', style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep))),
          if (m.kcal > 0) ...[
            Text('${m.kcal}', style: t.textTheme.titleLarge?.copyWith(color: AppColors.gold)),
            const SizedBox(width: 4),
            Text('KCAL', style: AppTypography.eyebrow(AppColors.muted).copyWith(fontSize: 10)),
          ],
        ]),
        const SizedBox(height: AppSpacing.s16),
        Text('SEXE', style: AppTypography.eyebrow(AppColors.muted).copyWith(fontSize: 11)),
        const SizedBox(height: 6),
        SegPair(a: 'Femme', b: 'Homme', first: m.sexe == 'f', onChanged: (f) => onChanged(m.copyWith(sexe: f ? 'f' : 'h'))),
        const SizedBox(height: AppSpacing.s16),
        Row(children: [
          Expanded(child: NumField(label: 'Âge', value: m.age, onChanged: (v) => onChanged(m.copyWith(age: v)))),
          const SizedBox(width: AppSpacing.s16),
          Expanded(child: NumField(label: 'Taille', value: m.taille, suffix: 'cm', onChanged: (v) => onChanged(m.copyWith(taille: v)))),
        ]),
        const SizedBox(height: AppSpacing.s16),
        Row(children: [
          Expanded(child: NumField(label: 'Poids', value: m.poids, suffix: 'kg', onChanged: (v) => onChanged(m.copyWith(poids: v)))),
          const SizedBox(width: AppSpacing.s16),
          Expanded(child: LabeledDropdown(label: 'Activité', value: m.act, options: {for (final e in kActivities.entries) e.key: e.value.label}, onChanged: (v) => onChanged(m.copyWith(act: v)))),
        ]),
        const SizedBox(height: AppSpacing.s16),
        LabeledDropdown(label: 'Régime', value: m.diet, options: {for (final e in kDietPlans.entries) e.key: e.value.label}, onChanged: (v) => onChanged(m.copyWith(diet: v))),
      ]),
    );
  }
}
