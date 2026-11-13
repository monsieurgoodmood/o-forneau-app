import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/pantry.dart';
import '../../data/recipe.dart';
import '../../data/recipes_repository.dart';
import '../../l10n/app_localizations.dart';

/// « Cuisiner avec mon frigo » — on déclare ce qu'on a, on classe les recettes par couverture
/// (« il vous manque N ingrédients »). Port 1:1 du web.
class FrigoScreen extends ConsumerStatefulWidget {
  const FrigoScreen({super.key});
  @override
  ConsumerState<FrigoScreen> createState() => _FrigoScreenState();
}

class _FrigoScreenState extends ConsumerState<FrigoScreen> {
  final _ctl = TextEditingController();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  void _add([String? v]) {
    final x = (v ?? _ctl.text).trim();
    if (x.isEmpty) return;
    ref.read(pantryProvider.notifier).add(x);
    _ctl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final pantry = ref.watch(pantryProvider);
    final all = ref.watch(recipesProvider).asData?.value ?? const <Recipe>[];
    final ranked = pantry.isEmpty ? const <(Recipe, Coverage)>[] : rankByPantry(all, pantry).take(40).toList();
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);
    final sugg = kPantrySuggestions.where((s) => !pantry.contains(s)).take(10).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        title: Text(L.of(context).monFrigo, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
        actions: [if (pantry.isNotEmpty) TextButton(onPressed: () => ref.read(pantryProvider.notifier).clear(), child: const Text('Vider', style: TextStyle(color: AppColors.muted)))],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
        children: [
          Text(L.of(context).cuisinerAvecMonFrigo2, style: AppTypography.eyebrow(AppColors.gold)),
          const SizedBox(height: AppSpacing.s8),
          Text("QuL.of(context).estCeQueJai ?", style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
          const SizedBox(height: AppSpacing.s8),
          Text(L.of(context).ajoutezVosIngredientsOnClasseLes, style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
          const SizedBox(height: AppSpacing.s16),
          Container(
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))]),
            child: TextField(
              controller: _ctl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
              decoration: InputDecoration(
                hintText: L.of(context).unIngredientExTomate,
                prefixIcon: const Icon(Icons.kitchen_outlined, color: AppColors.green),
                suffixIcon: IconButton(onPressed: _add, icon: const Icon(Icons.add_circle, color: AppColors.green)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          if (pantry.isNotEmpty) ...[
            Wrap(spacing: AppSpacing.s8, runSpacing: AppSpacing.s8, children: [
              for (final p in pantry)
                Chip(
                  label: Text(p),
                  backgroundColor: AppColors.greenSoft,
                  side: BorderSide.none,
                  deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.greenDeep),
                  onDeleted: () => ref.read(pantryProvider.notifier).remove(p),
                ),
            ]),
            const SizedBox(height: AppSpacing.s16),
          ],
          if (sugg.isNotEmpty) ...[
            Text(L.of(context).suggestions, style: AppTypography.eyebrow(AppColors.muted).copyWith(fontSize: 11)),
            const SizedBox(height: AppSpacing.s8),
            Wrap(spacing: AppSpacing.s8, runSpacing: AppSpacing.s8, children: [
              for (final s in sugg)
                ActionChip(label: Text(s), avatar: const Icon(Icons.add, size: 16, color: AppColors.green), backgroundColor: AppColors.white, side: const BorderSide(color: AppColors.line), onPressed: () => _add(s)),
            ]),
            const SizedBox(height: AppSpacing.s24),
          ],
          if (pantry.isNotEmpty) ...[
            Text('${ranked.length} recette${ranked.length > 1 ? 's' : ''} possible${ranked.length > 1 ? 's' : ''}', style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: AppSpacing.s16),
            for (final e in ranked) _CovCard(recipe: e.$1, cov: e.$2),
          ],
        ],
      ),
    );
  }
}

class _CovCard extends StatelessWidget {
  final Recipe recipe;
  final Coverage cov;
  const _CovCard({required this.recipe, required this.cov});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final full = cov.miss == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          onTap: () => context.push('/recipe/${recipe.slug}'),
          child: Row(children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.r16)),
              child: CachedNetworkImage(imageUrl: recipe.imageUrl, width: 100, height: 100, fit: BoxFit.cover, placeholder: (c, _) => Container(color: AppColors.greenSoft, width: 100, height: 100)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(recipe.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep, fontSize: 16)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: full ? AppColors.greenSoft : const Color(0xFFF1E6D4), borderRadius: BorderRadius.circular(999)),
                      child: Text(full ? L.of(context).toutEstLa : 'Il manque ${cov.miss}', style: t.textTheme.labelSmall?.copyWith(color: full ? AppColors.greenDeep : const Color(0xFF5A4318), fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Text('${cov.have}/${cov.total} ingrédients', style: t.textTheme.labelSmall),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
