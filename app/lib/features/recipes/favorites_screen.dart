import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/favorites.dart';
import '../../data/recipes_repository.dart';
import 'recipes_list_screen.dart' show RecipeCard;

/// Mes favoris — hors-ligne, synchronisés avec le compte quand connecté.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final favs = ref.watch(favoritesProvider);
    final all = ref.watch(recipesProvider).asData?.value ?? const [];
    final list = all.where((r) => favs.contains(r.slug)).toList();
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        title: Text('Mes favoris', style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
      ),
      body: list.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(margin * 2),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.favorite_border, size: 40, color: AppColors.gold),
                  const SizedBox(height: AppSpacing.s16),
                  Text('Aucun favori pour l’instant', style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
                  const SizedBox(height: AppSpacing.s8),
                  Text('Touchez le cœur sur une recette pour la retrouver ici.', textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
                ]),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s24),
              itemBuilder: (context, i) => RecipeCard(recipe: list[i]),
            ),
    );
  }
}
