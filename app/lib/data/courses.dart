import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';
import 'recipe.dart';

/// Portions choisies recette par recette.
///
/// Le curseur de portions vivait dans l'état local de la fiche : en quittant l'écran, le
/// choix disparaissait, et la liste de courses retombait sur les portions d'origine. Une
/// personne qui cuisine pour cinq se retrouvait avec les quantités pour quatre.
class PortionsNotifier extends StateNotifier<Map<String, int>> {
  final SharedPreferences _p;
  static const _cle = 'mf_portions';

  PortionsNotifier(this._p) : super(_charger(_p));

  static Map<String, int> _charger(SharedPreferences p) {
    try {
      final brut = p.getString(_cle);
      if (brut == null) return {};
      return (jsonDecode(brut) as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> poser(String slug, int portions) async {
    if (portions < 1) return;
    state = {...state, slug: portions};
    await _p.setString(_cle, jsonEncode(state));
  }

  int pour(Recipe r) => state[r.slug] ?? (r.serv == 0 ? 2 : r.serv);
}

final portionsProvider =
    StateNotifierProvider<PortionsNotifier, Map<String, int>>((ref) => PortionsNotifier(ref.watch(prefsProvider)));

/// Une ligne de courses : un ingrédient, ses quantités par unité, et d'où il vient.
///
/// On n'additionne que des unités identiques. « 200 g » et « 2 tranches » de pain ne font
/// pas « 202 » : les deux montants restent côte à côte, ce qui est juste et lisible.
class LigneCourses {
  final String nom;
  final Map<String, double> parUnite; // unité normalisée → total
  final List<String> recettes;
  final bool quantiteInconnue; // « sel », « poivre » : aucune quantité chiffrée

  const LigneCourses({
    required this.nom,
    required this.parUnite,
    required this.recettes,
    this.quantiteInconnue = false,
  });

  /// « 5 tranches », « 125 g », « 1,5 cuillère à café », ou '' si rien de chiffré.
  String get quantite {
    if (quantiteInconnue && parUnite.isEmpty) return '';
    final morceaux = <String>[];
    final unites = parUnite.keys.toList()..sort();
    for (final u in unites) {
      final v = parUnite[u]!;
      if (v <= 0) continue;
      morceaux.add(u.isEmpty ? _nombre(v) : '${_nombre(v)} $u');
    }
    return morceaux.join(' + ');
  }

  /// Arrondi lisible : on ne demande pas « 3,75 gouttes » ni « 1,0000001 oignon ».
  static String _nombre(double v) {
    if ((v - v.roundToDouble()).abs() < 0.01) return v.round().toString();
    final arrondi = (v * 4).round() / 4; // au quart près : 0,25 / 0,5 / 0,75
    return arrondi.toString().replaceAll('.', ',');
  }
}

String normaliserUnite(String u) => u.trim().toLowerCase();

/// Agrège les ingrédients de plusieurs recettes, chacune à SES portions choisies.
///
/// [exclus] : ce que la personne a déjà (le frigo). [portionsDe] donne les portions
/// retenues pour une recette ; sans quoi on prend celles de la fiche.
List<LigneCourses> construireCourses({
  required List<Recipe> recettes,
  required int Function(Recipe) portionsDe,
  Iterable<String> exclus = const [],
}) {
  final dejaLa = exclus.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toList();
  final parNom = <String, Map<String, double>>{};
  final sources = <String, List<String>>{};
  final sansQuantite = <String>{};

  for (final r in recettes) {
    final base = r.serv == 0 ? 2 : r.serv;
    final facteur = portionsDe(r) / base;
    for (final ing in r.ingredients) {
      final nom = ing.name.trim();
      if (nom.isEmpty) continue;
      final cle = nom.toLowerCase();
      if (dejaLa.any((p) => cle.contains(p) || p.contains(cle))) continue;

      final unite = normaliserUnite(ing.unit);
      final totaux = parNom.putIfAbsent(nom, () => <String, double>{});
      if (ing.qty > 0) {
        totaux[unite] = (totaux[unite] ?? 0) + ing.qty * facteur;
      } else {
        sansQuantite.add(nom);
      }
      final depuis = sources.putIfAbsent(nom, () => <String>[]);
      if (!depuis.contains(r.title)) depuis.add(r.title);
    }
  }

  final lignes = parNom.entries
      .map((e) => LigneCourses(
            nom: e.key,
            parUnite: Map.fromEntries(e.value.entries.where((x) => x.value > 0)),
            recettes: sources[e.key] ?? const [],
            quantiteInconnue: sansQuantite.contains(e.key),
          ))
      .toList();
  lignes.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
  return lignes;
}
