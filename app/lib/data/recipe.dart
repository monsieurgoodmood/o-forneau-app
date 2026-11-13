/// Modèle Recette — miroir Dart du format de données web (window.MORE_RECIPES).
/// Immuable. Le parsing tolère les champs absents (certaines recettes n'ont pas de macros).
library;

class Ingredient {
  final double qty; // 0 = quantité non chiffrée (ex. « sel »)
  final String unit; // "" = sans unité (ex. œufs, pincées)
  final String name;
  final String? note;

  const Ingredient({required this.qty, required this.unit, required this.name, this.note});

  factory Ingredient.fromList(List<dynamic> l) {
    final meta = (l.length > 3 && l[3] is Map) ? l[3] as Map : const {};
    return Ingredient(
      qty: (l.isNotEmpty && l[0] is num) ? (l[0] as num).toDouble() : 0,
      unit: l.length > 1 ? (l[1]?.toString() ?? '') : '',
      name: l.length > 2 ? (l[2]?.toString() ?? '') : '',
      note: meta['note']?.toString(),
    );
  }
}

class RecipeStep {
  final String text;
  final int? seconds; // minuteur suggéré pour cette étape

  const RecipeStep({required this.text, this.seconds});

  factory RecipeStep.fromList(List<dynamic> l) => RecipeStep(
        text: l.isNotEmpty ? (l[0]?.toString() ?? '') : '',
        seconds: (l.length > 1 && l[1] is num) ? (l[1] as num).toInt() : null,
      );
}

class Macros {
  final int kcal;
  final int p; // protéines g
  final int l; // lipides g
  final int g; // glucides g
  final bool estimated;

  const Macros({required this.kcal, required this.p, required this.l, required this.g, required this.estimated});

  static Macros? fromMap(dynamic m) {
    if (m is! Map) return null;
    int i(String k) => (m[k] is num) ? (m[k] as num).round() : 0;
    return Macros(kcal: i('kcal'), p: i('p'), l: i('l'), g: i('g'), estimated: m['est'] == 1 || m['est'] == true);
  }
}

class Recipe {
  final String slug;
  final String title;
  final String product; // clé ustensile (poele, casserole, plat_four, ...)
  final String intro;
  final List<String> diets;
  final List<String> appl; // appareils requis (poele, four, ...)
  final int active; // min préparation active
  final int total; // min total, repos compris
  final int rest; // min de repos passif (froid, levee) inclus dans total
  final String diff; // difficulté
  final int serv; // portions de base
  final List<Ingredient> ingredients;
  final String titane; // astuce titane Forneau
  final List<RecipeStep> steps;
  final Macros? macros;
  final List<String> meal; // petit-dej, dejeuner, diner, gouter, encas, proteine, dessert
  final String img; // chemin relatif sur app.forneau.com
  final String role; // plat | sauce | base : une sauce ne tient pas lieu de repas
  final List<String> allerg; // allergenes certains (categories INCO)
  final List<String> allergDoute; // allergenes possibles : composition industrielle inconnue

  const Recipe({
    required this.slug,
    required this.title,
    required this.product,
    required this.intro,
    required this.diets,
    required this.appl,
    required this.active,
    required this.total,
    this.rest = 0,
    required this.diff,
    required this.serv,
    required this.ingredients,
    required this.titane,
    required this.steps,
    required this.macros,
    required this.meal,
    required this.img,
    this.role = 'plat',
    this.allerg = const [],
    this.allergDoute = const [],
  });

  /// Pour un filtre d'exclusion, le doute compte comme une presence : en allergie,
  /// on s'abstient plutot que de parier sur la composition d'un bouillon.
  bool contientAllergene(String cle) => allerg.contains(cle) || allergDoute.contains(cle);

  String get imageUrl => img.isEmpty ? '' : 'https://app.forneau.com/$img';

  factory Recipe.fromJson(Map<String, dynamic> j) {
    List<String> strList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String && v.isNotEmpty) return [v];
      return const [];
    }

    final ing = (j['ing'] as List?)?.whereType<List>().map((e) => Ingredient.fromList(e)).toList() ?? const <Ingredient>[];
    final steps = (j['steps'] as List?)?.whereType<List>().map((e) => RecipeStep.fromList(e)).toList() ?? const <RecipeStep>[];

    return Recipe(
      slug: j['slug']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      product: j['product']?.toString() ?? '',
      intro: j['intro']?.toString() ?? '',
      diets: strList(j['diets']),
      appl: strList(j['appl']),
      active: (j['active'] is num) ? (j['active'] as num).toInt() : 0,
      total: (j['total'] is num) ? (j['total'] as num).toInt() : 0,
      rest: (j['rest'] is num) ? (j['rest'] as num).toInt() : 0,
      diff: j['diff']?.toString() ?? '',
      serv: (j['serv'] is num) ? (j['serv'] as num).toInt() : 2,
      ingredients: ing,
      titane: j['titane']?.toString() ?? '',
      steps: steps,
      macros: Macros.fromMap(j['macros']),
      meal: strList(j['meal']),
      img: j['img']?.toString() ?? '',
      role: (j['role']?.toString().isNotEmpty ?? false) ? j['role'].toString() : 'plat',
      allerg: (j['allerg'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      allergDoute: (j['allerg_doute'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
