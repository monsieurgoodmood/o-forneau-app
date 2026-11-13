import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/favorites.dart';
import '../../data/courses.dart';
import '../../data/pantry.dart';
import '../../data/recipes_repository.dart';

/// Liste de courses — ingrédients manquants des recettes favorites (hors frigo), groupés,
/// cochables (coché = acheté). Port 1:1 du web.
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final favs = ref.watch(favoritesProvider);
    final pantry = ref.watch(pantryProvider).map(norm).toList();
    final cart = ref.watch(cartProvider);
    final all = ref.watch(recipesProvider).asData?.value ?? const [];
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);

    // Les quantites suivent jusqu'ici, a la portion choisie recette par recette :
    // une liste qui dit « pain de mie » sans dire combien oblige a rouvrir la fiche
    // dans le magasin (ticket A05).
    final portions = ref.watch(portionsProvider.notifier);
    final lignes = construireCourses(
      recettes: all.where((r) => favs.contains(r.slug)).toList(),
      portionsDe: portions.pour,
      exclus: pantry,
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        title: Text('Liste de courses', style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
        actions: [if (cart.isNotEmpty) TextButton(onPressed: () => ref.read(cartProvider.notifier).clear(), child: const Text('Décocher tout', style: TextStyle(color: AppColors.muted)))],
      ),
      body: lignes.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(margin * 2),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.shopping_basket_outlined, size: 40, color: AppColors.gold),
                  const SizedBox(height: AppSpacing.s16),
                  Text('Liste vide', style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
                  const SizedBox(height: AppSpacing.s8),
                  Text("Ajoutez des recettes en favori : leurs ingrédients manquants s'accumulent ici.", textAlign: TextAlign.center, style: t.textTheme.bodyMedium),
                ]),
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
              children: [
                Text('À ACHETER', style: AppTypography.eyebrow(AppColors.gold)),
                const SizedBox(height: AppSpacing.s8),
                Text('${lignes.length} article${lignes.length > 1 ? 's' : ''}', style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
                const SizedBox(height: AppSpacing.s16),
                for (final ligne in lignes)
                  Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                    decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(AppRadius.r16)),
                    child: CheckboxListTile(
                      value: cart.contains(ligne.nom),
                      activeColor: AppColors.green,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (_) => ref.read(cartProvider.notifier).toggle(ligne.nom),
                      title: Text(
                        ligne.quantite.isEmpty ? ligne.nom : '${ligne.quantite} · ${ligne.nom}',
                        style: t.textTheme.bodyLarge?.copyWith(
                          decoration: cart.contains(ligne.nom) ? TextDecoration.lineThrough : null,
                          color: cart.contains(ligne.nom) ? AppColors.muted : AppColors.ink),
                      ),
                      subtitle: Text(
                        '${ligne.recettes.first}${ligne.recettes.length > 1 ? ' +${ligne.recettes.length - 1}' : ''}',
                        style: t.textTheme.labelSmall),
                    ),
                  ),
              ],
            ),
    );
  }
}
