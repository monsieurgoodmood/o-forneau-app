import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/community.dart';
import '../../data/programme.dart';
import '../../data/recipe.dart';
import '../../data/recipes_repository.dart';
import '../frigo/frigo_screen.dart';
import '../acces/paywall_screen.dart';
import '../auth/exiger_compte.dart';
import '../createurs/createurs_screen.dart';
import '../programme/foyer_screen.dart';
import '../programme/programme_screen.dart';
import '../../l10n/app_localizations.dart';

const _base = 'https://app.forneau.com/';

/// Moment de la journée → type de repas suggéré (port 1:1 du web).
({String meal, String label}) daypart() {
  final h = DateTime.now().hour;
  if (h >= 5 && h < 10) return (meal: 'petit-dej', label: 'Pour bien démarrer la journée');
  if (h >= 10 && h < 14) return (meal: 'dejeuner', label: 'Des idées pour le déjeuner');
  if (h >= 14 && h < 18) return (meal: 'gouter', label: 'Une pause gourmande ?');
  if (h >= 18 && h < 23) return (meal: 'diner', label: 'Des idées pour ce soir');
  return (meal: 'diner', label: 'Un petit creux ?');
}

/// Idées du jour : repas du moment, compatibles avec les régimes du foyer, rotation par seed.
final suggestionsProvider = Provider<({String label, List<Recipe> recs})>((ref) {
  final all = ref.watch(recipesProvider).asData?.value ?? const <Recipe>[];
  final d = daypart();
  final diets = foyerDiets(ref.watch(foyerProvider), ref.watch(progProvider));
  const n = 6;
  var pool = all.where((r) => r.img.isNotEmpty && r.meal.contains(d.meal) && recipeMatchesAll(r, diets)).toList();
  if (pool.length < n) pool = all.where((r) => r.img.isNotEmpty && r.meal.contains(d.meal)).toList();
  if (pool.length < n) pool = all.where((r) => r.img.isNotEmpty).toList();
  final out = <Recipe>[];
  if (pool.isNotEmpty) {
    var i = (ref.watch(menuSeedProvider) * 7) % pool.length;
    final seen = <String>{};
    while (out.length < n && seen.length < pool.length) {
      final r = pool[i % pool.length];
      if (seen.add(r.slug)) out.add(r);
      i++;
    }
  }
  return (label: d.label, recs: out);
});

/// Accueil — réplique du web : hero « Bien manger, simplement », idées du jour, cartes du menu.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);
    final sug = ref.watch(suggestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        title: Text('Accueil', style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
        children: [
          // Hero
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r16 + 6),
            child: AspectRatio(
              aspectRatio: 0.95,
              child: Stack(fit: StackFit.expand, children: [
                CachedNetworkImage(imageUrl: '${_base}img/hero-forneau.jpg', fit: BoxFit.cover, placeholder: (c, _) => Container(color: AppColors.greenSoft)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.45, 1], colors: [Colors.transparent, Color(0xCC1B2A19)]),
                  ),
                ),
                Positioned(
                  left: 0, right: 0, bottom: 22,
                  child: Column(children: [
                    Text(L.of(context).oForneau, style: AppTypography.eyebrow(Colors.white).copyWith(letterSpacing: 3)),
                    const SizedBox(height: 6),
                    Text(L.of(context).bienMangerSimplement, textAlign: TextAlign.center, style: t.textTheme.displayLarge?.copyWith(color: Colors.white, fontSize: 32)),
                    const SizedBox(height: 4),
                    Text(L.of(context).parMaisonForneau, style: t.textTheme.titleLarge?.copyWith(color: Colors.white, fontStyle: FontStyle.italic, fontWeight: FontWeight.w400)),
                  ]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(L.of(context).desRecettesAuTitaneAdapteesA,
              textAlign: TextAlign.center, style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.s24),

          // Idées du jour
          if (sug.recs.isNotEmpty) ...[
            Row(children: [
              Expanded(child: Text(sug.label, style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep))),
              IconButton(onPressed: () => ref.read(menuSeedProvider.notifier).state++, icon: const Icon(Icons.refresh, color: AppColors.green)),
            ]),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sug.recs.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s16),
                itemBuilder: (context, i) => _SugCard(recipe: sug.recs[i]),
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
          ],

          // Menu
          _MenuCard(icon: L.of(context).icAssistant, title: L.of(context).trouverUneRecette, desc: L.of(context).toutesLesRecettesFiltreesCommeVous, featured: true, onTap: () => context.go('/')),
          _MenuCard(icon: L.of(context).icProgramme, title: L.of(context).monProgrammeNutritionnel, desc: L.of(context).unObjectifUneJourneeDeRepas, onTap: () async {
            if (!await exigerPremium(context, ref, fonction: L.of(context).leProgrammeNutritionnel)) return;
            if (!context.mounted) return;
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgrammeScreen()));
          }),
          _MenuCard(icon: L.of(context).icFoyer, title: L.of(context).pourQuiJeCuisine, desc: L.of(context).soloOuFamilleQuantitesEtNutrition, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FoyerScreen()))),
          _MenuCard(icon: L.of(context).icFrigo, title: L.of(context).cuisinerAvecMonFrigo, desc: L.of(context).ceQueVousPouvezFaireAvec, onTap: () async {
            if (!await exigerPremium(context, ref, fonction: L.of(context).cuisinerAvecMonFrigo)) return;
            if (!context.mounted) return;
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FrigoScreen()));
          }),
          _MenuCard(icon: L.of(context).icAssistant, title: L.of(context).mesCreateursPreferes, desc: L.of(context).ditesNousQuiSuivreOnVa, onTap: () async {
            if (!await exigerCompte(context, ref, fonction: L.of(context).proposerUnCreateur)) return;
            if (!context.mounted) return;
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateursScreen()));
          }),
        ],
      ),
    );
  }
}

class _SugCard extends ConsumerWidget {
  final Recipe recipe;
  const _SugCard({required this.recipe});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final s = ref.watch(statsOfProvider(recipe.slug));
    return SizedBox(
      width: 170,
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          onTap: () => context.push('/recipe/${recipe.slug}'),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.r16)),
              child: CachedNetworkImage(imageUrl: recipe.imageUrl, height: 104, width: 170, fit: BoxFit.cover, placeholder: (c, _) => Container(color: AppColors.greenSoft, height: 104)),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(recipe.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.labelLarge?.copyWith(color: AppColors.greenDeep)),
                const SizedBox(height: 4),
                Text('${recipe.total} min · ${recipe.diff}${s.count > 0 ? ' · ★ ${s.avg.toStringAsFixed(1).replaceAll('.', ',')}' : ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.labelSmall),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String icon, title, desc;
  final bool featured;
  final VoidCallback onTap;
  const _MenuCard({required this.icon, required this.title, required this.desc, this.featured = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.r16 + 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r16 + 4),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r16 + 4),
              border: Border.all(color: featured ? AppColors.gold.withValues(alpha: 0.6) : AppColors.line.withValues(alpha: 0.5)),
              boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.r16),
                child: CachedNetworkImage(imageUrl: '${_base}img/3d/$icon.png', width: 72, height: 72, fit: BoxFit.cover,
                    placeholder: (c, _) => Container(color: AppColors.greenSoft, width: 72, height: 72),
                    errorWidget: (c, _, __) => Container(color: AppColors.greenSoft, width: 72, height: 72, child: const Icon(Icons.restaurant, color: AppColors.green))),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
                  const SizedBox(height: 2),
                  Text(desc, style: t.textTheme.bodyMedium),
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ]),
          ),
        ),
      ),
    );
  }
}
