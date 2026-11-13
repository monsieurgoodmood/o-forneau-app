import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';
import 'supabase_client.dart';

/// Favoris : persistés localement (hors-ligne), synchronisés dans user_profiles.app_state.favs
/// quand un compte est connecté (même emplacement que le web → favoris partagés web/app).
class FavoritesNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;
  final Ref _ref;
  static const _key = 'mf_favs';

  FavoritesNotifier(this._prefs, this._ref) : super(_load(_prefs)) {
    _pullFromCloud();
  }

  static Set<String> _load(SharedPreferences p) {
    try {
      final raw = p.getString(_key);
      if (raw == null) return {};
      return (jsonDecode(raw) as List).map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  bool isFav(String slug) => state.contains(slug);

  Future<void> toggle(String slug) async {
    final s = Set<String>.from(state);
    s.contains(slug) ? s.remove(slug) : s.add(slug);
    state = s;
    await _prefs.setString(_key, jsonEncode(s.toList()));
    _pushToCloud();
  }

  /// Fusion au démarrage : union local ∪ cloud (on ne perd jamais un favori).
  Future<void> _pullFromCloud() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final row = await supabase.from('user_profiles').select('app_state').eq('id', user.id).maybeSingle();
      final cloud = (row?['app_state'] is Map) ? (row!['app_state'] as Map)['favs'] : null;
      final merged = Set<String>.from(state);
      if (cloud is List) merged.addAll(cloud.map((e) => e.toString()));
      if (merged.length != state.length) {
        state = merged;
        await _prefs.setString(_key, jsonEncode(merged.toList()));
      }
      // On remonte TOUJOURS l'union, meme si le nuage n'a rien apporte : sinon les
      // favoris pris en mode invite ne rejoignent jamais le compte qu'on vient de creer
      // (ticket A19). La condition precedente ne poussait que si le nuage etait plus
      // riche que le local, c'est-a-dire jamais dans ce cas-la.
      if (merged.isNotEmpty) _pushToCloud();
    } catch (_) {}
  }

  Future<void> _pushToCloud() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    try {
      final row = await supabase.from('user_profiles').select('app_state').eq('id', user.id).maybeSingle();
      final st = Map<String, dynamic>.from((row?['app_state'] is Map) ? row!['app_state'] as Map : {});
      st['favs'] = state.toList();
      await supabase.from('user_profiles').update({'app_state': st}).eq('id', user.id);
    } catch (_) {}
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  // Re-crée le notifier à la connexion/déconnexion pour refaire la fusion cloud.
  ref.watch(currentUserProvider);
  return FavoritesNotifier(ref.watch(prefsProvider), ref);
});
