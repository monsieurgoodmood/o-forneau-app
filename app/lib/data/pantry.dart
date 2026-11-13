import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';
import 'recipe.dart';
import 'supabase_client.dart';

/// « Dans mon frigo » + liste de courses — port 1:1 du web (norm, coverage, mf_pantry / mf_cart,
/// cloud app_state.pantry / app_state.cart).

/// Normalisation web : minuscules, sans diacritiques, sans « s » final.
String norm(String s) {
  var x = s.toLowerCase().trim();
  const from = 'àáâäãåāçćčèéêëēėęîïíīįìôöòóœøōõûüùúūñńÿ';
  const to = 'aaaaaaacccceeeeeeeiiiiiioooooooouuuuunny';
  final sb = StringBuffer();
  for (final ch in x.split('')) {
    final i = from.indexOf(ch);
    sb.write(i >= 0 ? to[i] : ch);
  }
  x = sb.toString();
  if (x.endsWith('s')) x = x.substring(0, x.length - 1);
  return x.trim();
}

const List<String> kPantrySuggestions = [
  'pois chiches', 'tomate', 'citron', 'avocat', 'banane', 'pomme', 'oignon', 'ail', 'lait', 'œuf', 'farine',
  'épinards', 'coriandre', 'yaourt nature', 'beurre de cacahuète', 'quinoa',
];

class Coverage {
  final int have, total;
  const Coverage(this.have, this.total);
  int get miss => total - have;
  double get ratio => total == 0 ? 0 : have / total;
}

/// Couverture d'une recette par le frigo (ingrédients-clés uniquement, match par inclusion dans les 2 sens).
Coverage coverage(Recipe r, Set<String> pantry) {
  final key = r.ingredients; // les ingrédients « staple » ne sont pas marqués dans l'export → tous comptés
  if (pantry.isEmpty) return Coverage(0, key.length);
  final p = pantry.map(norm).toList();
  var have = 0;
  for (final ing in key) {
    final n = norm(ing.name);
    if (p.any((x) => n.contains(x) || x.contains(n))) have++;
  }
  return Coverage(have, key.length);
}

/// Recettes faisables avec le frigo, classées par couverture décroissante puis manquants croissants.
List<(Recipe, Coverage)> rankByPantry(List<Recipe> all, Set<String> pantry) {
  final out = <(Recipe, Coverage)>[];
  for (final r in all) {
    final c = coverage(r, pantry);
    if (c.have > 0) out.add((r, c));
  }
  out.sort((a, b) {
    final d = b.$2.ratio.compareTo(a.$2.ratio);
    return d != 0 ? d : a.$2.miss.compareTo(b.$2.miss);
  });
  return out;
}

// ---------- Persistance (locale + cloud, mêmes clés que le web) ----------

Future<void> _cloudMerge(Ref ref, String key, List<String> value) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;
  try {
    final row = await supabase.from('user_profiles').select('app_state').eq('id', user.id).maybeSingle();
    final st = Map<String, dynamic>.from((row?['app_state'] is Map) ? row!['app_state'] as Map : {});
    st[key] = value;
    await supabase.from('user_profiles').update({'app_state': st}).eq('id', user.id);
  } catch (_) {}
}

class _SetNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _p;
  final Ref _ref;
  final String _key; // 'pantry' | 'cart'
  _SetNotifier(this._p, this._ref, this._key) : super(_load(_p, _key)) {
    _pull();
  }
  static Set<String> _load(SharedPreferences p, String key) {
    try {
      final raw = p.getString('mf_$key');
      if (raw != null) return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {}
    return {};
  }
  Future<void> _save() async {
    await _p.setString('mf_$_key', jsonEncode(state.toList()));
    _cloudMerge(_ref, _key, state.toList());
  }
  Future<void> _pull() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final row = await supabase.from('user_profiles').select('app_state').eq('id', user.id).maybeSingle();
      final cloud = (row?['app_state'] is Map) ? (row!['app_state'] as Map)[_key] : null;
      final merged = Set<String>.from(state);
      if (cloud is List) merged.addAll(cloud.map((e) => e.toString()));
      if (merged.length != state.length) {
        state = merged;
        await _save();
      } else if (merged.isNotEmpty) {
        // Meme raison que pour les favoris : ce qui a ete saisi en invite doit rejoindre
        // le compte, y compris quand le nuage est vide (ticket A19).
        await _save();
      }
    } catch (_) {}
  }
  Future<void> toggle(String v) async {
    final s = Set<String>.from(state);
    s.contains(v) ? s.remove(v) : s.add(v);
    state = s;
    await _save();
  }
  Future<void> add(String v) async {
    final x = v.trim();
    if (x.isEmpty || state.contains(x)) return;
    state = {...state, x};
    await _save();
  }
  Future<void> remove(String v) async {
    state = Set<String>.from(state)..remove(v);
    await _save();
  }
  Future<void> clear() async {
    state = {};
    await _save();
  }
}

final pantryProvider = StateNotifierProvider<_SetNotifier, Set<String>>((ref) {
  ref.watch(currentUserProvider);
  return _SetNotifier(ref.watch(prefsProvider), ref, 'pantry');
});

/// Articles cochés (achetés) dans la liste de courses.
final cartProvider = StateNotifierProvider<_SetNotifier, Set<String>>((ref) {
  ref.watch(currentUserProvider);
  return _SetNotifier(ref.watch(prefsProvider), ref, 'cart');
});
