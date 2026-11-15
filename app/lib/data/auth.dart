import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

/// Injecté dans main() avec l'instance réelle.
final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('prefs non initialisé'));

/// Mode invité (« Continuer sans compte ») — persistant localement.
class GuestNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  GuestNotifier(this._prefs) : super(_prefs.getBool('mf_guest') ?? false);
  Future<void> setGuest() async {
    await _prefs.setBool('mf_guest', true);
    state = true;
  }
}

final guestProvider = StateNotifierProvider<GuestNotifier, bool>((ref) => GuestNotifier(ref.watch(prefsProvider)));

/// Flux de session Supabase.
final authChangesProvider = StreamProvider<AuthState>(
    (ref) => supabasePret ? supabase.auth.onAuthStateChange : const Stream<AuthState>.empty());

/// Utilisateur courant (null = déconnecté — ou client non initialisé : même chose pour l'app).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authChangesProvider);
  return supabasePret ? supabase.auth.currentUser : null;
});

/// Actions d'authentification.
class AuthActions {
  Future<void> signUp({
    required String email,
    required String password,
    required String prenom,
    String? nom,
    String? telephone,
    bool marketing = false,
  }) async {
    await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'prenom': prenom,
        if (nom != null && nom.isNotEmpty) 'nom': nom,
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
        'marketing_consent': marketing,
      },
    );
  }

  Future<void> signIn({required String email, required String password}) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => supabase.auth.signOut();
}

final authActionsProvider = Provider<AuthActions>((ref) => AuthActions());
