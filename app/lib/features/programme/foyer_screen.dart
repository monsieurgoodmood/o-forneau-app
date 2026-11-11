import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/programme.dart';
import 'programme_widgets.dart';

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
        title: Text('Mon foyer', style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
        children: [
          const Eyebrow('Mon foyer'),
          Text('Pour qui cuisinez-vous ?', style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
          const SizedBox(height: AppSpacing.s8),
          Text('On adapte les quantités des recettes, et si vous le souhaitez les valeurs nutritionnelles, à votre foyer. Tout est optionnel : commencez simple.',
              style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.s24),

          const Eyebrow('Je cuisine…'),
          SegPair(
            a: 'Juste pour moi', subA: '1 personne', b: 'Pour plusieurs', subB: 'famille, amis…',
            first: solo,
            onChanged: (s) => set(foyer.copyWith(mode: s ? 'solo' : 'famille')),
          ),
          if (!solo) ...[
            const SizedBox(height: AppSpacing.s24),
            const Eyebrow('Combien de personnes ?'),
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
                      TextSpan(text: 'Affiner la nutrition ', style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep, fontSize: 18)),
                      const TextSpan(text: 'Renseignez âge, taille, poids, activité et régime — on calcule les besoins de chacun et le menu du jour convient à tous.'),
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
