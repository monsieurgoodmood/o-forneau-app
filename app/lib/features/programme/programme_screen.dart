import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/programme.dart';
import 'foyer_screen.dart';
import 'programme_widgets.dart';

/// Programme nutritionnel — réplique du web : profil, objectif, type d'alimentation,
/// besoins calculés, et menu du jour compatible avec tous les régimes du foyer.
class ProgrammeScreen extends ConsumerWidget {
  const ProgrammeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final prog = ref.watch(progProvider);
    final foyer = ref.watch(foyerProvider);
    final target = progTarget(prog);
    final plan = ref.watch(dailyPlanProvider);
    final gouter = ref.watch(gouterProvider);
    final me = prog.me;
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);
    final setProg = ref.read(progProvider.notifier).set;
    final diets = foyerDiets(foyer, prog);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        title: Text('Programme', style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoyerScreen())),
            icon: const Icon(Icons.group_outlined, color: AppColors.green, size: 18),
            label: Text('Mon foyer', style: t.textTheme.labelLarge?.copyWith(color: AppColors.green)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
        children: [
          const Eyebrow('Programme nutritionnel'),
          Text('Votre programme sur mesure', style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
          const SizedBox(height: AppSpacing.s8),
          Text('Renseignez votre profil et votre objectif : on calcule vos besoins et on compose une journée adaptée. Estimation indicative, pas un avis médical.',
              style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.s24),

          // Profil
          const Eyebrow('Votre profil'),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SEXE', style: AppTypography.eyebrow(AppColors.muted).copyWith(fontSize: 11)),
              const SizedBox(height: 6),
              SegPair(a: 'Femme', b: 'Homme', first: me.sexe == 'f', onChanged: (f) => setProg(prog.copyWith(me: me.copyWith(sexe: f ? 'f' : 'h')))),
              const SizedBox(height: AppSpacing.s16),
              Row(children: [
                Expanded(child: NumField(label: 'Âge', value: me.age, onChanged: (v) => setProg(prog.copyWith(me: me.copyWith(age: v))))),
                const SizedBox(width: AppSpacing.s16),
                Expanded(child: NumField(label: 'Taille', value: me.taille, suffix: 'cm', onChanged: (v) => setProg(prog.copyWith(me: me.copyWith(taille: v))))),
              ]),
              const SizedBox(height: AppSpacing.s16),
              Row(children: [
                Expanded(child: NumField(label: 'Poids', value: me.poids, suffix: 'kg', onChanged: (v) => setProg(prog.copyWith(me: me.copyWith(poids: v))))),
                const SizedBox(width: AppSpacing.s16),
                const Expanded(child: SizedBox()),
              ]),
              const SizedBox(height: AppSpacing.s16),
              LabeledDropdown(
                label: "Niveau d'activité",
                value: me.act,
                options: {for (final e in kActivities.entries) e.key: e.value.label},
                onChanged: (v) => setProg(prog.copyWith(me: me.copyWith(act: v))),
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                target.tdee > 0 ? 'Dépense estimée ~${target.tdee} kcal/jour (Mifflin-St Jeor).' : 'Renseignez taille et poids pour un calcul personnalisé.',
                style: t.textTheme.bodyMedium,
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Objectif
          const Eyebrow('Votre objectif'),
          SizedBox(
            height: 132,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final e in kGoals.entries) ...[
                ChoiceCard(
                  icon: e.key == 'perte' ? Icons.local_fire_department_outlined : (e.key == 'masse' ? Icons.auto_awesome : Icons.adjust),
                  label: e.value.label, sub: e.value.sub, on: prog.goal == e.key,
                  onTap: () => setProg(prog.copyWith(goal: e.key)),
                ),
                const SizedBox(width: AppSpacing.s16),
              ],
            ]),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Type d'alimentation
          const Eyebrow("Type d'alimentation"),
          SizedBox(
            height: 132,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final e in kDietPlans.entries) ...[
                ChoiceCard(
                  icon: Icons.eco_outlined,
                  label: e.value.label, sub: 'P${e.value.p} · L${e.value.l} · G${e.value.g}', on: me.diet == e.key,
                  onTap: () => setProg(prog.copyWith(me: me.copyWith(diet: e.key))),
                ),
                const SizedBox(width: AppSpacing.s16),
              ],
            ]),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Besoins
          const Eyebrow('Vos besoins'),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Objectif ${target.kcal} kcal/jour', style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
              const SizedBox(height: AppSpacing.s8),
              Row(children: [
                _Macro('Protéines', '${target.p} g'),
                _Macro('Lipides', '${target.l} g'),
                _Macro('Glucides', '${target.g} g'),
              ]),
            ]),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Menu du jour
          Row(children: [
            const Expanded(child: Eyebrow('Menu du jour')),
            TextButton.icon(
              onPressed: () => ref.read(menuSeedProvider.notifier).state++,
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.green),
              label: Text('Autre menu', style: t.textTheme.labelLarge?.copyWith(color: AppColors.green)),
            ),
          ]),
          if (foyer.mode != 'solo')
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Text('Compatible avec les régimes du foyer : ${diets.map((d) => kDietPlans[d]?.label ?? d).join(', ')}.', style: t.textTheme.bodyMedium),
            ),
          for (final item in plan) _PlanCard(item: item),
          Row(children: [
            Text('Ajouter un goûter', style: t.textTheme.labelLarge),
            const Spacer(),
            Switch(value: gouter, activeColor: AppColors.green, onChanged: (v) => ref.read(gouterProvider.notifier).state = v),
          ]),
          const SizedBox(height: AppSpacing.s8),
          Builder(builder: (_) {
            final total = plan.fold<int>(0, (a, i) => a + (i.recipe.macros?.kcal ?? 0));
            final pct = (total / (target.kcal < 1 ? 1 : target.kcal)).clamp(0.0, 1.0);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$total kcal sur ${target.kcal} (par portion)', style: t.textTheme.labelMedium),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AppColors.greenSoft, color: AppColors.green)),
            ]);
          }),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  final String l, v;
  const _Macro(this.l, this.v);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(v, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
          Text(l, style: Theme.of(context).textTheme.labelSmall),
        ]),
      );
}

class _PlanCard extends StatelessWidget {
  final PlanItem item;
  const _PlanCard({required this.item});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final r = item.recipe;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          onTap: () => context.push('/recipe/${r.slug}'),
          child: Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.r16)),
              child: CachedNetworkImage(imageUrl: r.imageUrl, width: 110, height: 110, fit: BoxFit.cover, placeholder: (c, _) => Container(color: AppColors.greenSoft, width: 110, height: 110)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.label.toUpperCase(), style: AppTypography.eyebrow(AppColors.gold)),
                  const SizedBox(height: 4),
                  Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep, fontSize: 17)),
                  const SizedBox(height: 4),
                  Text('${r.macros?.kcal ?? 0} kcal · ${r.total} min', style: t.textTheme.labelSmall),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
