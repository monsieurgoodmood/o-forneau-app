import 'package:flutter/material.dart';

/// Libellés métier répliqués 1:1 du web (app.js DIETS / PRODUCTS / MEALS).

class MealType {
  final String key;
  final String label;
  const MealType(this.key, this.label);
}

const List<MealType> kMeals = [
  MealType('petit-dej', 'Petit-déjeuner'),
  MealType('dejeuner', 'Déjeuner'),
  MealType('diner', 'Dîner'),
  MealType('gouter', 'Goûter'),
  MealType('encas', 'En-cas'),
  MealType('proteine', 'Pause protéinée'),
  MealType('dessert', 'Dessert'),
];

/// Régimes : l = libellé long (fiche), s = libellé court (eyebrow carte).
class DietDef {
  final String long;
  final String short;
  const DietDef(this.long, this.short);
}

const Map<String, DietDef> kDiets = {
  'vegan': DietDef('100 % végétale', 'Végétale'),
  'vegetarien': DietDef('Végétarien', 'Végétarien'),
  'sans_gluten': DietDef('Sans gluten', 'Sans gluten'),
  'sans_lactose': DietDef('Sans lactose', 'Sans lactose'),
  'hypocalorique': DietDef('Léger', 'Léger'),
};

/// Ustensile Forneau : n = nom complet, d = tagline, have = vrai produit, h = handle forneau.com.
class ProductDef {
  final String name;
  final String tagline;
  final bool have;
  final String handle;
  final IconData icon;
  const ProductDef(this.name, this.tagline, this.have, this.handle, this.icon);

  /// Nom allégé pour la ligne ustensile des cartes (" Forneau"/" titane" retirés).
  String get shortName => name.replaceAll(' Forneau', '').replaceAll(' titane', '');
  String get url => 'https://forneau.com/products/$handle';
}

const Map<String, ProductDef> kProducts = {
  'poele': ProductDef('Poêle titane Forneau', 'Titane pur, sans PFAS, garantie à vie', true, 'poele-titane-forneau', Icons.restaurant_outlined),
  'sauteuse': ProductDef('Sauteuse 24 cm titane', 'Sautés et plats mijotés', true, 'la-sauteuse-forneau-24-cm-titane-pur', Icons.restaurant_outlined),
  'wok': ProductDef('Wok 24 cm titane', 'Sautés vifs, woks', true, 'wok-titane-forneau-24cm', Icons.ramen_dining_outlined),
  'casserole': ProductDef('Casserole 18 cm titane', 'Currys, soupes, céréales', true, 'casserole-titane-18-cm-sans-pfas', Icons.soup_kitchen_outlined),
  'marmite': ProductDef('Marmite 24 cm titane', 'Grands volumes, pâtes, bouillons', true, 'marmite-titane-24-cm-sans-pfas', Icons.soup_kitchen_outlined),
  'crepiere': ProductDef('Crêpière titane', 'Pancakes, crêpes, galettes', true, 'crepiere-titane-forneau', Icons.flatware_outlined),
  'planche': ProductDef('Planche titane Forneau', 'Découpe hygiénique, inrayable', true, 'planche-titane-forneau', Icons.square_outlined),
  'plat_four': ProductDef('Plat à four titane', 'Crumbles, gratins, cookies — à venir', false, '', Icons.bakery_dining_outlined),
  'moule': ProductDef('Moule à cake titane', 'Cakes et gâteaux — à venir', false, '', Icons.bakery_dining_outlined),
  'bol': ProductDef('Bol titane', 'Porridge, service — à venir', false, '', Icons.restaurant_outlined),
};

String mealLabel(String key) => kMeals.firstWhere((m) => m.key == key, orElse: () => MealType(key, key)).label;
DietDef? dietDef(String key) => kDiets[key];
ProductDef productDef(String key) => kProducts[key] ?? const ProductDef('Ustensile Forneau', '', false, '', Icons.restaurant_outlined);
