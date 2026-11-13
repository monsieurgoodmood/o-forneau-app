// La liste de courses est lue dans un magasin, le téléphone à la main. Une ligne sans
// quantité (« pain de mie », « chou blanc ») oblige à rouvrir la recette rayon par rayon.
// Critères repris du ticket A05 : 5 tranches de pain et 125 g de chou pour 5 portions.

import 'package:flutter_test/flutter_test.dart';

import 'package:o_forneau/data/courses.dart';
import 'package:o_forneau/data/recipe.dart';

Recipe recette(String slug, String titre, int serv, List<Ingredient> ing) => Recipe(
      slug: slug, title: titre, product: 'poele', intro: '', diets: const [], appl: const [],
      active: 10, total: 20, diff: 'Facile', serv: serv, ingredients: ing,
      titane: '', steps: const [], macros: null, meal: const [], img: '',
    );

void main() {
  group('A05 — les quantités survivent jusqu’à la liste', () {
    final sando = recette('sando', 'Sando au poisson', 4, const [
      Ingredient(qty: 4, unit: 'tranches', name: 'pain de mie'),
      Ingredient(qty: 100, unit: 'g', name: 'chou blanc'),
      Ingredient(qty: 0, unit: '', name: 'sel'),
    ]);

    test('à portions inchangées, la quantité de la fiche est reprise', () {
      final l = construireCourses(recettes: [sando], portionsDe: (_) => 4);
      expect(l.firstWhere((x) => x.nom == 'pain de mie').quantite, '4 tranches');
      expect(l.firstWhere((x) => x.nom == 'chou blanc').quantite, '100 g');
    });

    test('à 5 portions : 5 tranches de pain et 125 g de chou', () {
      final l = construireCourses(recettes: [sando], portionsDe: (_) => 5);
      expect(l.firstWhere((x) => x.nom == 'pain de mie').quantite, '5 tranches');
      expect(l.firstWhere((x) => x.nom == 'chou blanc').quantite, '125 g');
    });

    test('un ingrédient sans quantité reste listé, sans chiffre inventé', () {
      final l = construireCourses(recettes: [sando], portionsDe: (_) => 5);
      final sel = l.firstWhere((x) => x.nom == 'sel');
      expect(sel.quantite, '');
      expect(sel.quantiteInconnue, isTrue);
    });
  });

  group('cumul entre recettes', () {
    test('deux recettes partageant un ingrédient s’additionnent', () {
      final a = recette('a', 'A', 2, const [Ingredient(qty: 100, unit: 'g', name: 'farine')]);
      final b = recette('b', 'B', 2, const [Ingredient(qty: 50, unit: 'g', name: 'farine')]);
      final l = construireCourses(recettes: [a, b], portionsDe: (r) => 2);
      final farine = l.firstWhere((x) => x.nom == 'farine');
      expect(farine.quantite, '150 g');
      expect(farine.recettes, ['A', 'B']);
    });

    test('les unités incompatibles ne sont pas additionnées', () {
      final a = recette('a', 'A', 2, const [Ingredient(qty: 200, unit: 'g', name: 'pain')]);
      final b = recette('b', 'B', 2, const [Ingredient(qty: 2, unit: 'tranches', name: 'pain')]);
      final l = construireCourses(recettes: [a, b], portionsDe: (r) => 2);
      expect(l.first.quantite, '200 g + 2 tranches');
    });

    test('chaque recette garde SES portions', () {
      final a = recette('a', 'A', 2, const [Ingredient(qty: 100, unit: 'g', name: 'farine')]);
      final b = recette('b', 'B', 2, const [Ingredient(qty: 100, unit: 'g', name: 'farine')]);
      final l = construireCourses(recettes: [a, b], portionsDe: (r) => r.slug == 'a' ? 4 : 2);
      expect(l.first.quantite, '300 g'); // 200 + 100
    });

    test('la même recette deux fois ne double pas la ligne source', () {
      final a = recette('a', 'A', 2, const [Ingredient(qty: 100, unit: 'g', name: 'farine')]);
      final l = construireCourses(recettes: [a, a], portionsDe: (_) => 2);
      expect(l.first.recettes, ['A']);
    });
  });

  group('frigo', () {
    test('ce qu’on a déjà n’est pas racheté', () {
      final a = recette('a', 'A', 2, const [
        Ingredient(qty: 100, unit: 'g', name: 'farine'),
        Ingredient(qty: 2, unit: '', name: 'œufs'),
      ]);
      final l = construireCourses(recettes: [a], portionsDe: (_) => 2, exclus: ['farine']);
      expect(l.map((x) => x.nom), ['œufs']);
    });
  });

  group('arrondis lisibles', () {
    test('un tiers de portion ne donne pas 3,333333', () {
      final a = recette('a', 'A', 3, const [Ingredient(qty: 1, unit: '', name: 'oignon')]);
      final l = construireCourses(recettes: [a], portionsDe: (_) => 4);
      expect(l.first.quantite, '1,25');
    });

    test('un demi-oignon reste un demi', () {
      final a = recette('a', 'A', 4, const [Ingredient(qty: 0.5, unit: '', name: 'oignon rouge')]);
      final l = construireCourses(recettes: [a], portionsDe: (_) => 4);
      expect(l.first.quantite, '0,5');
    });
  });
}
