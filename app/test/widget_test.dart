import 'package:flutter_test/flutter_test.dart';
import 'package:o_forneau/data/recipe.dart';

void main() {
  test('Recipe.fromJson parse les champs essentiels', () {
    final r = Recipe.fromJson({
      'slug': 'abc',
      'title': 'Test',
      'product': 'poele',
      'diets': ['vegan'],
      'meal': 'diner',
      'serv': 4,
      'total': 30,
      'ing': [[2.0, 'cl', 'lait', {}]],
      'steps': [['Chauffer', 600]],
    });
    expect(r.slug, 'abc');
    expect(r.meal, contains('diner'));
    expect(r.ingredients.first.name, 'lait');
    expect(r.steps.first.seconds, 600);
  });
}
