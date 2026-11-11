import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/catalog.dart';
import '../../data/favorites.dart';
import '../../data/recipe.dart';
import '../../data/recipes_repository.dart';
import 'cook_mode_screen.dart';
import 'reviews_section.dart';
import '../frigo/courses_screen.dart';

/// Fiche recette — réplique du web (hero, pastilles, bloc ustensile Forneau, Mode cuisine).
class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String slug;
  const RecipeDetailScreen({super.key, required this.slug});
  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  int? _servings;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final recipe = ref.watch(recipeBySlugProvider(widget.slug));

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.creamTop),
        body: Center(
          child: FilledButton(onPressed: () => context.go('/'), child: const Text('Retour aux recettes')),
        ),
      );
    }

    final servings = _servings ?? (recipe.serv == 0 ? 2 : recipe.serv);
    final factor = recipe.serv == 0 ? 1.0 : servings / recipe.serv;
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);
    final prod = productDef(recipe.product);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.creamTop,
            surfaceTintColor: Colors.transparent,
            foregroundColor: AppColors.greenDeep,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep, fontSize: 18)),
            actions: [
              IconButton(
                tooltip: 'Favori',
                onPressed: () => ref.read(favoritesProvider.notifier).toggle(recipe.slug),
                icon: Icon(ref.watch(favoritesProvider).contains(recipe.slug) ? Icons.favorite : Icons.favorite_border, color: AppColors.green),
              ),
            ],
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.imageUrl.isEmpty
                  ? Container(color: AppColors.greenSoft)
                  : CachedNetworkImage(imageUrl: recipe.imageUrl, fit: BoxFit.cover, errorWidget: (c, _, __) => Container(color: AppColors.greenSoft)),
              collapseMode: CollapseMode.parallax,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(margin, AppSpacing.s24, margin, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(recipe.title, style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
                const SizedBox(height: AppSpacing.s16),
                if (recipe.intro.isNotEmpty)
                  Text(recipe.intro, style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
                const SizedBox(height: AppSpacing.s24),

                // Pastilles meta (temps / ustensile / difficulté)
                Wrap(spacing: AppSpacing.s8, runSpacing: AppSpacing.s8, children: [
                  _MetaPill(icon: Icons.schedule, label: recipe.active > 0 ? '${recipe.active} min actifs · ${recipe.total} min' : '${recipe.total} min'),
                  _MetaPill(icon: prod.icon, label: prod.shortName),
                  _MetaPill(icon: Icons.auto_awesome, label: recipe.diff.isEmpty ? 'Facile' : recipe.diff),
                ]),
                const SizedBox(height: AppSpacing.s16),

                // Pastilles régime (plates, or)
                if (recipe.diets.isNotEmpty)
                  Wrap(spacing: AppSpacing.s8, runSpacing: AppSpacing.s8, children: [
                    for (final d in recipe.diets)
                      if (dietDef(d) != null) _DietPill(label: dietDef(d)!.long.toUpperCase()),
                  ]),
                const SizedBox(height: AppSpacing.s24),

                // Bloc ustensile Forneau
                _UstensileCard(product: prod),
                const SizedBox(height: AppSpacing.s24),

                // Portions
                _ServingsStepper(servings: servings, onChanged: (v) => setState(() => _servings = v)),
                const SizedBox(height: AppSpacing.s24),

                _SectionTitle('Ingrédients'),
                ...recipe.ingredients.map((ing) => _IngredientRow(ing: ing, factor: factor)),
                const SizedBox(height: AppSpacing.s24),

                if (recipe.titane.isNotEmpty) ...[
                  _TitaneTip(text: recipe.titane, product: prod),
                  const SizedBox(height: AppSpacing.s24),
                ],

                _SectionTitle('Préparation'),
                ...List.generate(recipe.steps.length, (i) => _StepRow(index: i + 1, step: recipe.steps[i])),

                if (recipe.macros != null) ...[
                  const SizedBox(height: AppSpacing.s24),
                  _SectionTitle('Valeurs par portion'),
                  _MacrosRow(macros: recipe.macros!),
                ],
                const SizedBox(height: AppSpacing.s32),
                ReviewsSection(slug: recipe.slug),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CookBar(recipe: recipe),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s16),
        child: Text(text, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.greenDeep)),
      );
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 17, color: AppColors.gold),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ]),
    );
  }
}

class _DietPill extends StatelessWidget {
  final String label;
  const _DietPill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(label, style: AppTypography.eyebrow(AppColors.gold)),
    );
  }
}

class _UstensileCard extends StatelessWidget {
  final ProductDef product;
  const _UstensileCard({required this.product});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(AppRadius.r8)),
            child: Icon(product.icon, color: AppColors.green),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('USTENSILE FORNEAU', style: AppTypography.eyebrow(AppColors.gold)),
                const SizedBox(height: 4),
                Text(product.name, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep, fontSize: 19)),
                Text(product.tagline, style: t.textTheme.bodyMedium),
              ],
            ),
          ),
          if (product.have)
            TextButton(
              onPressed: () => launchUrl(Uri.parse(product.url), mode: LaunchMode.externalApplication),
              child: Text('Voir le produit', style: t.textTheme.labelMedium?.copyWith(color: AppColors.green)),
            ),
        ],
      ),
    );
  }
}

class _ServingsStepper extends StatelessWidget {
  final int servings;
  final ValueChanged<int> onChanged;
  const _ServingsStepper({required this.servings, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    Widget btn(IconData ic, VoidCallback? onTap) => Material(
          color: AppColors.greenSoft,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(10), child: Icon(ic, size: 20, color: onTap == null ? AppColors.muted : AppColors.green)),
          ),
        );
    return Row(
      children: [
        Text('Portions', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.greenDeep)),
        const Spacer(),
        btn(Icons.remove, servings > 1 ? () => onChanged(servings - 1) : null),
        Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16), child: Text('$servings', style: Theme.of(context).textTheme.titleLarge)),
        btn(Icons.add, servings < 20 ? () => onChanged(servings + 1) : null),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final Ingredient ing;
  final double factor;
  const _IngredientRow({required this.ing, required this.factor});

  static String _fmtQty(double q) {
    if (q <= 0) return '';
    final r = q >= 10 ? q.roundToDouble() : (q * 10).roundToDouble() / 10;
    return r == r.roundToDouble() ? r.toInt().toString() : r.toStringAsFixed(1).replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final qty = _fmtQty(ing.qty * factor);
    final head = [qty, ing.unit].where((e) => e.isNotEmpty).join(' ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: AppSpacing.s16),
            child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(style: t.textTheme.bodyLarge, children: [
                if (head.isNotEmpty) TextSpan(text: '$head ', style: t.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: AppColors.greenDeep)),
                TextSpan(text: ing.name),
                if (ing.note != null && ing.note!.isNotEmpty) TextSpan(text: '  — ${ing.note}', style: t.textTheme.bodyMedium),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int index;
  final RecipeStep step;
  const _StepRow({required this.index, required this.step});

  static String _fmtDuration(int s) {
    if (s < 60) return '$s s';
    final m = s ~/ 60, r = s % 60;
    return r == 0 ? '$m min' : '$m min $r s';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle),
            child: Text('$index', style: t.textTheme.labelLarge?.copyWith(color: AppColors.greenDeep)),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 4), child: Text(step.text, style: t.textTheme.bodyLarge)),
                if (step.seconds != null && step.seconds! > 0) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.r8), border: Border.all(color: AppColors.line)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.timer_outlined, size: 15, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text(_fmtDuration(step.seconds!), style: t.textTheme.labelMedium),
                    ]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TitaneTip extends StatelessWidget {
  final String text;
  final ProductDef product;
  const _TitaneTip({required this.text, required this.product});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.auto_awesome, size: 17, color: AppColors.gold),
            const SizedBox(width: AppSpacing.s8),
            Expanded(child: Text('LE GESTE TITANE — ${product.shortName.toUpperCase()}', style: AppTypography.eyebrow(AppColors.gold))),
          ]),
          const SizedBox(height: AppSpacing.s8),
          Text(text, style: t.textTheme.bodyLarge?.copyWith(color: AppColors.greenDeep)),
        ],
      ),
    );
  }
}

class _MacrosRow extends StatelessWidget {
  final Macros macros;
  const _MacrosRow({required this.macros});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget cell(String v, String l) => Expanded(
          child: Column(children: [
            Text(v, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: 2),
            Text(l, style: t.textTheme.labelSmall),
          ]),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(AppRadius.r16)),
      child: Row(children: [
        cell('${macros.kcal}', 'kcal'),
        cell('${macros.p} g', 'Protéines'),
        cell('${macros.l} g', 'Lipides'),
        cell('${macros.g} g', 'Glucides'),
      ]),
    );
  }
}

class _CookBar extends StatelessWidget {
  final Recipe recipe;
  const _CookBar({required this.recipe});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      padding: EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, MediaQuery.paddingOf(context).bottom + AppSpacing.s8),
      child: Row(
        children: [
          Material(
            color: AppColors.white,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CoursesScreen())),
              child: const Padding(padding: EdgeInsets.all(14), child: Icon(Icons.shopping_basket_outlined, color: AppColors.green)),
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: FilledButton.icon(
              onPressed: recipe.steps.isEmpty
                  ? null
                  : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CookModeScreen(recipe: recipe))),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Mode cuisine'),
            ),
          ),
        ],
      ),
    );
  }
}
