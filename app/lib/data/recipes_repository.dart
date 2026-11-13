import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'community.dart';
import 'recipe.dart';

/// Langue d'affichage du catalogue. Posée par l'app d'après la langue du téléphone ;
/// le français est le repli, et c'est lui qui porte la vérité (régimes, allergènes,
/// rôles et minuteurs sont calculés sur le texte français, jamais re-détectés ailleurs).
final langueCatalogueProvider = StateProvider<String>((ref) => 'fr');

/// Langues pour lesquelles un catalogue traduit est embarqué.
const kLanguesCatalogue = {'fr', 'en', 'de', 'it', 'nl', 'es', 'pt'};

/// Charge les 406 recettes depuis l'asset JSON embarqué (hors-ligne, instantané).
final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final langue = ref.watch(langueCatalogueProvider);
  final chemin = (langue == 'fr' || !kLanguesCatalogue.contains(langue))
      ? 'assets/data/recipes.json'
      : 'assets/data/i18n/recipes_$langue.json';
  String raw;
  try {
    raw = await rootBundle.loadString(chemin);
  } catch (_) {
    // Un catalogue traduit manquant ne doit jamais vider l'app : on retombe sur le
    // français, qui est toujours là.
    raw = await rootBundle.loadString('assets/data/recipes.json');
  }
  final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  return list.map(Recipe.fromJson).toList(growable: false);
});

/// État des filtres de la liste (recherche + régimes + repas + tri « mieux notées »).
class RecipeFilter {
  final String query;
  final Set<String> diets;
  final Set<String> meals;
  /// Allergenes a EXCLURE. Le doute compte comme une presence (ticket A02).
  final Set<String> allergenes;
  final bool sortRated;

  const RecipeFilter({this.query = '', this.diets = const {}, this.meals = const {},
      this.allergenes = const {}, this.sortRated = false});

  RecipeFilter copyWith({String? query, Set<String>? diets, Set<String>? meals,
          Set<String>? allergenes, bool? sortRated}) =>
      RecipeFilter(
        query: query ?? this.query,
        diets: diets ?? this.diets,
        meals: meals ?? this.meals,
        allergenes: allergenes ?? this.allergenes,
        sortRated: sortRated ?? this.sortRated,
      );

  int get activeCount => diets.length + meals.length + allergenes.length + (sortRated ? 1 : 0);
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

  void toggleAllergene(String a) {
    final s = Set<String>.from(state.allergenes);
    s.contains(a) ? s.remove(a) : s.add(a);
    state = state.copyWith(allergenes: s);
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
    // Exclusion d'allergene : on ecarte aussi les doutes. Mieux vaut proposer moins
    // de recettes que d'en proposer une qui rende quelqu'un malade.
    if (f.allergenes.any(r.contientAllergene)) return false;
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
