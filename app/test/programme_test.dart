// Ticket A03 : les journées proposées doivent approcher la cible affichée. L'audit a
// mesuré 989 kcal, puis 1 123, en face d'une cible de 2 000. On vérifie sur le VRAI
// catalogue, pour plusieurs graines et plusieurs régimes.
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_forneau/data/programme.dart';
import 'package:o_forneau/data/recipe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<Recipe> toutes;

  setUpAll(() async {
    final brut = await rootBundle.loadString('assets/data/recipes.json');
    toutes = (jsonDecode(brut) as List)
        .cast<Map<String, dynamic>>()
        .map(Recipe.fromJson)
        .toList();
  });

  test('le catalogue est charge', () {
    expect(toutes.length, greaterThan(300));
  });

  group('A03 — la journee approche la cible', () {
    for (final cible in [1600, 2000, 2400]) {
      test('cible $cible kcal, dix journees differentes', () {
        final ecarts = <double>[];
        for (var graine = 0; graine < 10; graine++) {
          final plan = buildPlan(toutes, const [''], graine, cibleKcal: cible);
          expect(plan.length, 3, reason: 'trois repas attendus');
          ecarts.add(ecartCible(plan, cible));
        }
        final pire = ecarts.reduce((a, b) => a > b ? a : b);
        expect(pire, lessThan(kToleranceCible),
            reason: 'ecart maximal ${(pire * 100).toStringAsFixed(1)} % sur $cible kcal');
      });
    }

    test('sans cible, le comportement d avant est conserve', () {
      final plan = buildPlan(toutes, const [''], 3);
      expect(plan.length, 3);
    });

    test('regenerer change la journee', () {
      final a = buildPlan(toutes, const [''], 1, cibleKcal: 2000).map((p) => p.recipe.slug).toList();
      final b = buildPlan(toutes, const [''], 2, cibleKcal: 2000).map((p) => p.recipe.slug).toList();
      expect(a, isNot(equals(b)));
    });
  });

  group('A04 — aucune sauce ne tient lieu de repas', () {
    test('sur cent journees, jamais de sauce au dejeuner ni au diner', () {
      final fautes = <String>[];
      for (var graine = 0; graine < 100; graine++) {
        for (final item in buildPlan(toutes, const [''], graine, cibleKcal: 2000)) {
          if (item.label == 'Petit-déjeuner') continue;
          if (item.recipe.role == 'sauce' || item.recipe.role == 'base') {
            fautes.add('${item.label} : ${item.recipe.title}');
          }
        }
      }
      expect(fautes, isEmpty, reason: fautes.take(3).join(' | '));
    });
  });

  group('A27 — composer la journée au lieu de la rejouer', () {
    test('un repas verrouillé survit au changement de graine', () {
      // « Régénérer » incrémente la graine de 1 : c'est l'usage réel.
      final a = buildPlan(toutes, const [''], 1, cibleKcal: 2000);
      final garde = a[1].recipe.slug; // le déjeuner
      final b = buildPlan(toutes, const [''], 2, cibleKcal: 2000,
          verrous: {'dejeuner': garde});
      expect(b[1].recipe.slug, garde, reason: 'le déjeuner gardé ne doit pas bouger');
      expect(b[0].recipe.slug, isNot(a[0].recipe.slug), reason: 'le reste change bien');
    });

    test('les propositions tournent sur huit plats par créneau', () {
      // Conséquence assumée de _candidats : on ne propose que les huit plats les plus
      // proches de la cible. Au-delà, on retomberait sur des journées hors cible.
      final vus = <String>{};
      for (var g = 0; g < 20; g++) {
        vus.add(buildPlan(toutes, const [''], g, cibleKcal: 2000)[0].recipe.slug);
      }
      expect(vus.length, 8, reason: 'huit petits-déjeuners distincts, puis ça tourne');
    });

    test('remplacer un repas ne touche pas les autres', () {
      final a = buildPlan(toutes, const [''], 3, cibleKcal: 2000);
      final b = buildPlan(toutes, const [''], 3, cibleKcal: 2000,
          decalages: {'diner': 1});
      expect(b[2].recipe.slug, isNot(a[2].recipe.slug), reason: 'le dîner change');
      expect(b[0].recipe.slug, a[0].recipe.slug, reason: 'le petit-déjeuner reste');
      expect(b[1].recipe.slug, a[1].recipe.slug, reason: 'le déjeuner reste');
    });

    test('un verrou l emporte sur un remplacement', () {
      final a = buildPlan(toutes, const [''], 2, cibleKcal: 2000);
      final garde = a[2].recipe.slug;
      final b = buildPlan(toutes, const [''], 2, cibleKcal: 2000,
          verrous: {'diner': garde}, decalages: {'diner': 5});
      expect(b[2].recipe.slug, garde);
    });

    test('le créneau se déduit du libellé affiché', () {
      expect(creneauDe('Petit-déjeuner'), 'petit-dej');
      expect(creneauDe('Déjeuner'), 'dejeuner');
      expect(creneauDe('Dîner'), 'diner');
      expect(creneauDe('Goûter'), 'gouter');
    });

    test('tout verrouiller fige la journée entière', () {
      final a = buildPlan(toutes, const [''], 1, cibleKcal: 2000);
      final verrous = {
        'petit-dej': a[0].recipe.slug,
        'dejeuner': a[1].recipe.slug,
        'diner': a[2].recipe.slug,
      };
      final b = buildPlan(toutes, const [''], 42, cibleKcal: 2000, verrous: verrous);
      expect(b.map((p) => p.recipe.slug), a.map((p) => p.recipe.slug));
    });
  });
}