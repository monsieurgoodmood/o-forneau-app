import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'community.dart';
import 'recipe.dart';

/// Charge les 406 recettes depuis l'asset JSON embarqué (hors-ligne, instantané).
final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/recipes.json');
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list.map(Recipe.fromJson).toList(growable: false);
});

/// État des filtres de la liste (recherche + régimes + repas + tri « mieux notées »).
class RecipeFilter {
  final String query;
  final Set<String> diets;
  final Set<String> meals;
  final bool sortRated;

  const RecipeFilter({this.query = '', this.diets = const {}, this.meals = const {}, this.sortRated = false});

  RecipeFilter copyWith({String? query, Set<String>? diets, Set<String>? meals, bool? sortRated}) => RecipeFilter(
        query: query ?? this.query,
        diets: diets ?? this.diets,
        meals: meals ?? this.meals,
        sortRated: sortRated ?? this.sortRated,
      );

  int get activeCount => diets.length + meals.length + (sortRated ? 1 : 0);
}

class RecipeFilterNotifier extends StateNotifier<RecipeFilter> {
  RecipeFilterNotifier() : super(const RecipeFilter());

  void setQuery(String q) => state = state.copyWith(query: q);

  void toggleDiet(String d) {
    final s = Set<String>.from(state.diets);
    s.contains(d) ? s.remove(d) : s.add(d);
    state = state.copyWith(diets: s);
  }

  void toggleMeal(String m) {
    final s = Set<String>.from(state.meals);
    s.contains(m) ? s.remove(m) : s.add(m);
    state = state.copyWith(meals: s);
  }

  void toggleSortRated() => state = state.copyWith(sortRated: !state.sortRated);

  void clear() => state = const RecipeFilter();
}

final recipeFilterProvider =
    StateNotifierProvider<RecipeFilterNotifier, RecipeFilter>((ref) => RecipeFilterNotifier());

/// Liste filtrée dérivée (recherche titre/intro + ET sur régimes + OU sur repas), tri optionnel par note.
final filteredRecipesProvider = Provider<List<Recipe>>((ref) {
  final all = ref.watch(recipesProvider).asData?.value ?? const <Recipe>[];
  final f = ref.watch(recipeFilterProvider);
  final q = f.query.trim().toLowerCase();

  final list = all.where((r) {
    if (q.isNotEmpty && !(r.title.toLowerCase().contains(q) || r.intro.toLowerCase().contains(q))) return false;
    if (f.diets.isNotEmpty && !f.diets.every(r.diets.contains)) return false;
    if (f.meals.isNotEmpty && !f.meals.any((m) => r.meal.contains(m))) return false;
    return true;
  }).toList();

  if (f.sortRated) {
    final stats = ref.watch(statsMapProvider).asData?.value ?? const <String, RecipeStats>{};
    double score(Recipe r) {
      final s = stats[r.slug];
      if (s == null || s.count == 0) return -1;
      return s.avg + (s.count / 100); // à moyenne égale, le plus noté d'abord
    }
    list.sort((a, b) => score(b).compareTo(score(a)));
  }
  return list;
});

/// Accès direct à une recette par slug (fiche, deep link).
final recipeBySlugProvider = Provider.family<Recipe?, String>((ref, slug) {
  final all = ref.watch(recipesProvider).asData?.value ?? const <Recipe>[];
  for (final r in all) {
    if (r.slug == slug) return r;
  }
  return null;
});
