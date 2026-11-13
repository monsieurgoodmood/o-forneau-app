import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/catalog.dart';
import '../../data/community.dart';
import '../../data/favorites.dart';
import '../../data/recipe.dart';
import '../../data/recipes_repository.dart';
import 'favorites_screen.dart';
import '../programme/programme_screen.dart';
import '../home/home_screen.dart';
import '../auth/account_screen.dart';
import '../acces/paywall_screen.dart';
import '../frigo/courses_screen.dart';

/// Accueil « Les recettes » — réplique du web (crème, wordmark, cartes éditoriales).
class RecipesListScreen extends ConsumerWidget {
  const RecipesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesProvider);
    final filtered = ref.watch(filteredRecipesProvider);
    final filter = ref.watch(recipeFilterProvider);
    final notifier = ref.read(recipeFilterProvider.notifier);
    final width = MediaQuery.sizeOf(context).width;
    final margin = AppSpacing.screenMargin(width);
    final cols = width >= 900 ? 3 : (width >= 640 ? 2 : 1);
    final activeFilters = filter.activeCount;

    return Scaffold(
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.green)),
        error: (e, _) => Center(child: Padding(padding: EdgeInsets.all(margin), child: Text('Chargement impossible : $e'))),
        data: (_) => SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _Wordmark()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('Les recettes', style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.greenDeep)),
                          const Spacer(),
                          Text('${filtered.length}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.gold)),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text('recettes', style: Theme.of(context).textTheme.labelSmall),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      _SearchField(value: filter.query, onChanged: notifier.setQuery),
                      const SizedBox(height: AppSpacing.s16),
                      _FiltersButton(
                        count: activeFilters,
                        onTap: () => _openFilters(context, ref),
                      ),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(margin * 2),
                    child: Center(child: Text('Aucune recette ne correspond.', style: Theme.of(context).textTheme.bodyMedium)),
                  ),
                )
              else if (cols == 1)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(margin, AppSpacing.s8, margin, 100),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s24),
                    itemBuilder: (context, i) => RecipeCard(recipe: filtered[i]),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(margin, AppSpacing.s8, margin, 100),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: AppSpacing.s24,
                      crossAxisSpacing: AppSpacing.s24,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => RecipeCard(recipe: filtered[i]),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _BottomNav(current: 1),
    );
  }

  void _openFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _FiltersSheet(),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.creamTop,
      padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, AppSpacing.s16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.eco, color: AppColors.green, size: 30),
          const SizedBox(width: AppSpacing.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ô FORNEAU !',
                  style: AppTypography.textTheme(AppColors.greenDeep, AppColors.muted)
                      .titleLarge
                      ?.copyWith(fontSize: 24, letterSpacing: 2.5, color: AppColors.greenDeep)),
              Text('PAR MAISON FORNEAU · 1974', style: AppTypography.eyebrow(AppColors.gold).copyWith(fontSize: 10, letterSpacing: 1.6)),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Mon compte',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen())),
            icon: const Icon(Icons.person_outline, color: AppColors.green),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 22, offset: const Offset(0, 6))],
      ),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Rechercher une recette, un ingrédient…',
          hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
          prefixIcon: const Icon(Icons.search, color: AppColors.green),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 19, horizontal: 8),
        ),
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FiltersButton({required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune, size: 18, color: AppColors.gold),
              const SizedBox(width: AppSpacing.s8),
              Text('Filtres', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.greenDeep)),
              if (count > 0) ...[
                const SizedBox(width: AppSpacing.s8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                  child: Text('$count', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FiltersSheet extends ConsumerWidget {
  const _FiltersSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(recipeFilterProvider);
    final notifier = ref.read(recipeFilterProvider.notifier);
    Widget section(String title, List<Widget> chips) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.eyebrow(AppColors.gold)),
            const SizedBox(height: AppSpacing.s8),
            Wrap(spacing: AppSpacing.s8, runSpacing: AppSpacing.s8, children: chips),
            const SizedBox(height: AppSpacing.s24),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 0, AppSpacing.s24, AppSpacing.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtres', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
          const SizedBox(height: AppSpacing.s24),
          section('Repas', [
            for (final m in kMeals)
              _ChoicePill(label: m.label, selected: filter.meals.contains(m.key), onTap: () => notifier.toggleMeal(m.key)),
          ]),
          section('Régime', [
            for (final e in kDiets.entries)
              if (e.key == 'vegetarien' || e.key == 'vegan' || e.key == 'hypocalorique')
                _ChoicePill(label: e.value.long, selected: filter.diets.contains(e.key), onTap: () => notifier.toggleDiet(e.key)),
          ]),
          section('Tri', [
            _ChoicePill(label: 'Mieux notées', selected: filter.sortRated, onTap: notifier.toggleSortRated),
          ]),
          Row(
            children: [
              TextButton(onPressed: () => notifier.clear(), child: const Text('Tout effacer', style: TextStyle(color: AppColors.muted))),
              const Spacer(),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Voir les recettes')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoicePill({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green : AppColors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppColors.green : AppColors.line),
          ),
          child: Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: selected ? Colors.white : AppColors.ink)),
        ),
      ),
    );
  }
}

class RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  const RecipeCard({required this.recipe});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final stats = ref.watch(statsOfProvider(recipe.slug));
    final diet = recipe.diets.isNotEmpty ? dietDef(recipe.diets.first) : null;
    final prod = productDef(recipe.product);
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(AppRadius.r16 + 6),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r16 + 6),
        onTap: () => context.go('/recipe/${recipe.slug}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r16 + 6),
            boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 11,
                    child: recipe.imageUrl.isEmpty
                        ? Container(color: AppColors.greenSoft)
                        : CachedNetworkImage(
                            imageUrl: recipe.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (c, _) => Container(color: AppColors.greenSoft),
                            errorWidget: (c, _, __) => Container(color: AppColors.greenSoft, child: const Icon(Icons.restaurant, color: AppColors.gold)),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => ref.read(favoritesProvider.notifier).toggle(recipe.slug),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                        child: Icon(
                          ref.watch(favoritesProvider).contains(recipe.slug) ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (diet != null)
                      Row(children: [
                        const Icon(Icons.eco, size: 14, color: AppColors.gold),
                        const SizedBox(width: 5),
                        Text(diet.short.toUpperCase(), style: AppTypography.eyebrow(AppColors.gold)),
                      ]),
                    const SizedBox(height: 6),
                    Text(recipe.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(prod.icon, size: 15, color: AppColors.muted),
                      const SizedBox(width: 6),
                      Expanded(child: Text(prod.shortName, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodyMedium)),
                    ]),
                    const SizedBox(height: AppSpacing.s16),
                    Divider(height: 1, color: AppColors.line.withValues(alpha: 0.7)),
                    const SizedBox(height: AppSpacing.s8),
                    Row(children: [
                      const Icon(Icons.schedule, size: 15, color: AppColors.gold),
                      const SizedBox(width: 5),
                      Text('${recipe.total} min', style: t.textTheme.labelMedium),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.line, shape: BoxShape.circle)),
                      ),
                      const Icon(Icons.auto_awesome, size: 14, color: AppColors.gold),
                      const SizedBox(width: 5),
                      Text(recipe.diff.isEmpty ? 'Facile' : recipe.diff, style: t.textTheme.labelMedium),
                      if (stats.count > 0) ...[
                        const Spacer(),
                        const Icon(Icons.star_rounded, size: 16, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text(stats.avg.toStringAsFixed(1).replaceAll('.', ','), style: t.textTheme.labelMedium?.copyWith(color: AppColors.greenDeep)),
                      ],
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final int current;
  const _BottomNav({required this.current});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.creamTop,
        indicatorColor: AppColors.greenSoft,
        labelTextStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.labelSmall),
      ),
      child: NavigationBar(
        selectedIndex: current,
        height: 64,
        onDestinationSelected: (i) {
          if (i == 1) return;
          if (i == 4) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
            return;
          }
          if (i == 3) {
            // Les courses se preparent depuis le telephone, dans la cuisine ou dans le
            // magasin : elles ne peuvent pas vivre uniquement derriere une fiche recette
            // comme c etait le cas sur mobile (ticket A22).
            () async {
              if (!await exigerPremium(context, ref, fonction: 'La liste de courses')) return;
              if (!context.mounted) return;
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoursesScreen()));
            }();
            return;
          }
          if (i == 2) {
            () async {
              if (!await exigerPremium(context, ref, fonction: 'Le programme nutritionnel')) return;
              if (!context.mounted) return;
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgrammeScreen()));
            }();
            return;
          }
          if (i == 0) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
            return;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined, color: AppColors.muted), selectedIcon: Icon(Icons.home, color: AppColors.green), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.explore_outlined, color: AppColors.muted), selectedIcon: Icon(Icons.explore, color: AppColors.green), label: 'Recettes'),
          NavigationDestination(icon: Icon(Icons.tune_outlined, color: AppColors.muted), selectedIcon: Icon(Icons.tune, color: AppColors.green), label: 'Programme'),
          NavigationDestination(icon: Icon(Icons.shopping_basket_outlined, color: AppColors.muted), selectedIcon: Icon(Icons.shopping_basket, color: AppColors.green), label: 'Courses'),
          NavigationDestination(icon: Icon(Icons.favorite_border, color: AppColors.muted), selectedIcon: Icon(Icons.favorite, color: AppColors.green), label: 'Favoris'),
        ],
      ),
    );
  }
}
