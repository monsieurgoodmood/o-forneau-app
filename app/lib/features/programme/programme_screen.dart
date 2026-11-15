import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/courses.dart';
import '../../data/favorites.dart';
import '../../data/programme.dart';
import '../frigo/courses_screen.dart';
import 'foyer_screen.dart';
import 'programme_widgets.dart';
import '../../l10n/app_localizations.dart';

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
        title: Text(L.of(context).programme, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoyerScreen())),
            icon: const Icon(Icons.group_outlined, color: AppColors.green, size: 18),
            label: Text(L.of(context).monFoyer, style: t.textTheme.labelLarge?.copyWith(color: AppColors.green)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
        children: [
          Eyebrow(L.of(context).programmeNutritionnel),
          Text(L.of(context).votreProgrammeSurMesure, style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
          const SizedBox(height: AppSpacing.s8),
          Text(L.of(context).renseignezVotreProfilEtVotreObjectif,
              style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.s24),

          // Profil
          Eyebrow(L.of(context).votreProfil2),
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
                target.tdee > 0 ? 'Dépense estimée ~${target.tdee} kcal/jour (Mifflin-St Jeor).' : L.of(context).renseignezTailleEtPoidsPourUn,
                style: t.textTheme.bodyMedium,
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Objectif
          Eyebrow(L.of(context).votreObjectif),
          _GrilleChoix(children: [
            for (final e in kGoals.entries)
              (double l) => ChoiceCard(
                    width: l,
                    icon: e.key == 'perte' ? Icons.local_fire_department_outlined : (e.key == 'masse' ? Icons.auto_awesome : Icons.adjust),
                    label: e.value.label, sub: e.value.sub, on: prog.goal == e.key,
                    onTap: () => setProg(prog.copyWith(goal: e.key)),
                  ),
          ]),
          const SizedBox(height: AppSpacing.s24),

          // Type d'alimentation
          const Eyebrow("Type d'alimentation"),
          _GrilleChoix(children: [
            for (final e in kDietPlans.entries)
              (double l) => ChoiceCard(
                    width: l, icon: Icons.eco_outlined,
                    label: e.value.label, sub: e.value.desc, on: me.diet == e.key,
                    onTap: () => setProg(prog.copyWith(me: me.copyWith(diet: e.key))),
                  ),
          ]),
          const SizedBox(height: AppSpacing.s24),

          // Besoins
          Eyebrow(L.of(context).vosBesoins),
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Objectif ${target.kcal} kcal/jour', style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
              const SizedBox(height: AppSpacing.s8),
              Row(children: [
                _Macro(L.of(context).proteines, '${target.p} g', 'muscles'),
                _Macro('Lipides', '${target.l} g', L.of(context).bonsGras),
                _Macro('Glucides', '${target.g} g', 'énergie'),
              ]),
              const SizedBox(height: AppSpacing.s8),
              Text('Répartition : ${target.plan.p} % protéines · ${target.plan.l} % lipides · ${target.plan.g} % glucides de vos calories.', style: t.textTheme.labelSmall),
            ]),
          ),
          const SizedBox(height: AppSpacing.s24),

          // Menu du jour
          Row(children: [
            Expanded(child: Eyebrow(L.of(context).menuDuJour)),
            TextButton.icon(
              onPressed: () => ref.read(menuSeedProvider.notifier).state++,
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.green),
              label: Text(L.of(context).autreMenu, style: t.textTheme.labelLarge?.copyWith(color: AppColors.green)),
            ),
          ]),
          if (foyer.mode != 'solo')
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: Text('Compatible avec les régimes du foyer : ${diets.map((d) => kDietPlans[d]?.label ?? d).join(', ')}.', style: t.textTheme.bodyMedium),
            ),
          for (final item in plan) _PlanCard(item: item),
          // Envoyer la journee aux courses, pour le foyer choisi : le ticket A27 note
          // qu on pouvait regarder un menu sans jamais pouvoir l acheter.
          if (plan.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            OutlinedButton.icon(
              onPressed: () {
                final favs = ref.read(favoritesProvider.notifier);
                final portions = ref.read(portionsProvider.notifier);
                final parts = foyer.effectiveCount;
                for (final item in plan) {
                  if (!ref.read(favoritesProvider).contains(item.recipe.slug)) {
                    favs.toggle(item.recipe.slug);
                  }
                  if (parts > 1) portions.poser(item.recipe.slug, parts);
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(parts > 1
                      ? 'Journée ajoutée aux courses, pour $parts personnes.'
                      : 'Journée ajoutée aux courses.'),
                  action: SnackBarAction(
                    label: 'Voir',
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CoursesScreen())),
                  ),
                ));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              icon: const Icon(Icons.shopping_basket_outlined, size: 18),
              label: const Text('Ajouter la journée à mes courses'),
            ),
          ],
          Row(children: [
            Text(L.of(context).ajouterUnGouter, style: t.textTheme.labelLarge),
            const Spacer(),
            Switch(value: gouter, activeColor: AppColors.green, onChanged: (v) => ref.read(gouterProvider.notifier).state = v),
          ]),
          const SizedBox(height: AppSpacing.s8),
          Builder(builder: (_) {
            final total = totalKcal(plan);
            final pct = (total / (target.kcal < 1 ? 1 : target.kcal)).clamp(0.0, 1.0);
            final ecart = ecartCible(plan, target.kcal);
            // Un profil sans taille ni poids ne donne pas une cible personnelle : on
            // le dit, au lieu de laisser croire a un calcul sur mesure (ticket A03).
            final surMesure = me.taille > 0 && me.poids > 0;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(surMesure
                      ? '$total kcal sur ${target.kcal} (par portion)'
                      : 'Exemple de journée : $total kcal, pour un repere de ${target.kcal}',
                  style: t.textTheme.labelMedium),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(999), child: LinearProgressIndicator(value: pct, minHeight: 8, backgroundColor: AppColors.greenSoft, color: AppColors.green)),
              if (ecart > kToleranceCible) ...[
                const SizedBox(height: AppSpacing.s8),
                Text('Cette journée s’écarte de ${(ecart * 100).round()} % du repere. Régénérez-la, ou complétez votre profil pour un calcul plus juste.',
                    style: t.textTheme.labelSmall?.copyWith(color: AppColors.gold)),
              ],
              if (!surMesure) ...[
                const SizedBox(height: 4),
                Text(L.of(context).renseignezTailleEtPoidsPourUne,
                    style: t.textTheme.labelSmall),
              ],
            ]);
          }),
        ],
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  final String l, v, hint;
  const _Macro(this.l, this.v, this.hint);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(v, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
          Text(l, style: Theme.of(context).textTheme.labelMedium),
          Text(hint, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.gold)),
        ]),
      );
}

class _PlanCard extends ConsumerWidget {
  final PlanItem item;
  const _PlanCard({required this.item});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final r = item.recipe;
    final creneau = creneauDe(item.label);
    final verrouille = ref.watch(repasVerrouillesProvider)[creneau] == r.slug;
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
                  Text(item.label.toUpperCase(), style: AppTypography.eyebrow()),
                  const SizedBox(height: 4),
                  Text(r.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep, fontSize: 17)),
                  const SizedBox(height: 6),
                  // Remplacer UN repas sans rejouer la journee, et garder un plat qu on
                  // vient d accepter : « Regenerer » emportait tout (ticket A27).
                  Row(children: [
                    _ActionRepas(
                      icone: Icons.refresh,
                      libelle: 'Remplacer',
                      actif: !verrouille,
                      onTap: () {
                        final d = {...ref.read(decalageRepasProvider)};
                        d[creneau] = (d[creneau] ?? 0) + 1;
                        ref.read(decalageRepasProvider.notifier).state = d;
                      },
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _ActionRepas(
                      icone: verrouille ? Icons.lock : Icons.lock_open,
                      libelle: verrouille ? 'Gardé' : 'Garder',
                      actif: true,
                      enRelief: verrouille,
                      onTap: () {
                        final v = {...ref.read(repasVerrouillesProvider)};
                        verrouille ? v.remove(creneau) : v[creneau] = r.slug;
                        ref.read(repasVerrouillesProvider.notifier).state = v;
                      },
                    ),
                  ]),
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

/// Grille de choix qui ne deborde jamais : deux colonnes sur telephone, trois des que
/// la largeur le permet. Remplace les listes horizontales, qui coupaient le dernier
/// choix au bord de l ecran et obligeaient a deviner qu il fallait faire glisser.
class _GrilleChoix extends StatelessWidget {
  final List<Widget Function(double largeur)> children;
  const _GrilleChoix({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const espace = AppSpacing.s8;
      final colonnes = c.maxWidth >= 560 ? 3 : 2;
      final largeur = (c.maxWidth - espace * (colonnes - 1)) / colonnes;
      return Wrap(
        spacing: espace,
        runSpacing: espace,
        children: [for (final f in children) f(largeur)],
      );
    });
  }
}

/// Petite action sous un repas du programme : discrete, mais atteignable au pouce.
class _ActionRepas extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final bool actif;
  final bool enRelief;
  final VoidCallback onTap;
  const _ActionRepas({required this.icone, required this.libelle, required this.actif,
      required this.onTap, this.enRelief = false});

  @override
  Widget build(BuildContext context) {
    final couleur = enRelief ? AppColors.green : AppColors.muted;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: actif ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 15, color: actif ? couleur : AppColors.line),
          const SizedBox(width: 4),
          Text(libelle, style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: actif ? couleur : AppColors.line)),
        ]),
      ),
    );
  }
}
