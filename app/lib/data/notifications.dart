import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth.dart';
import 'favorites.dart';
import 'mesure.dart';
import 'pantry.dart';
import 'programme.dart';
import 'recipes_repository.dart';
import 'supabase_client.dart';

/// Notifications push — consentement, inscription, profil d'usage, ouverture.
///
/// ─── Deux consentements, pas un ────────────────────────────────────────────────────────
///
/// La mesure d'audience (GA4, anonyme) et les notifications sont deux questions distinctes,
/// posées séparément, révocables séparément. On ne déduit jamais l'une de l'autre. Le
/// système n'accepte même pas d'approximation : la permission du téléphone est demandée
/// APRÈS que la personne a dit oui à notre propre question, jamais à froid au lancement.
///
/// ─── Le profil d'usage ──────────────────────────────────────────────────────────────────
///
/// Pour qu'une notification parle de ce que la personne fait vraiment (son frigo, ses
/// favoris, ce qu'elle a cuisiné) plutôt que d'une relance générique, l'appareil envoie au
/// serveur un profil compact : compteurs par fonction, derniers slugs, contenu du frigo,
/// filtres habituels. Il est constitué ICI, localement, à partir des événements que
/// [Mesure] voit passer — mais sans dépendre du consentement GA4 : ce sont des réglages
/// locaux, qui ne quittent l'appareil que si les notifications sont activées, et vers nos
/// seuls serveurs. Jamais d'e-mail, de prénom ni de texte libre dedans.
///
/// ─── Firebase, mais seulement pour le transport ─────────────────────────────────────────
///
/// FCM est le seul canal possible pour réveiller un téléphone Android. On n'embarque que
/// `firebase_messaging` : pas d'Analytics, pas de Crashlytics. Le jeton FCM identifie
/// l'appareil auprès de Google, pas la personne ; il n'est stocké que chez nous.
class Notifications {
  static const _cleChoix = 'mf_notif';
  static const _cleCats = 'mf_notif_cats';
  static const _cleUsage = 'mf_usage';
  static const _cleSync = 'mf_notif_sync';
  static const _cleSessions = 'mf_sessions';
  static const _dureeChoix = Duration(days: 365);

  final SharedPreferences _p;
  final Ref _ref;
  Notifications(this._p, this._ref);

  bool? _choix;
  Map<String, dynamic>? _usage;
  String? _jeton;

  // ── Consentement ──────────────────────────────────────────────────────────────────

  /// `true` activées, `false` refusées, `null` pas encore demandé (ou choix d'il y a un an).
  bool? get choix {
    if (_choix != null) return _choix;
    try {
      final brut = _p.getString(_cleChoix);
      if (brut == null) return null;
      final d = jsonDecode(brut) as Map<String, dynamic>;
      final quand = DateTime.fromMillisecondsSinceEpoch((d['t'] as num).toInt());
      if (DateTime.now().difference(quand) > _dureeChoix) return null;
      return _choix = d['ok'] == true;
    } catch (_) {
      return null;
    }
  }

  Future<void> _garder(bool ok) async {
    _choix = ok;
    await _p.setString(_cleChoix, jsonEncode({'ok': ok, 't': DateTime.now().millisecondsSinceEpoch}));
  }

  /// Nombre de sessions ouvertes : on ne pose la question qu'à partir de la deuxième, quand
  /// la personne a vu ce que l'app donne et a une raison de vouloir qu'on la prévienne.
  int get sessions => _p.getInt(_cleSessions) ?? 0;
  Future<void> compterSession() => _p.setInt(_cleSessions, sessions + 1);

  /// La question doit-elle être posée maintenant ? Jamais quand le transport n'existe pas
  /// (plateforme sans configuration Firebase) : demander une permission qu'on ne saura pas
  /// honorer serait un mensonge.
  bool get aDemander => disponible && choix == null && sessions >= 2;

  /// Firebase a-t-il démarré sur cet appareil ? Faux sur une plateforme sans configuration
  /// (iOS tant que la clé APNs n'est pas déposée, bureau, tests).
  static bool disponible = false;

  /// Réponse à NOTRE question. Un oui déclenche la permission système, puis l'inscription.
  /// Si le téléphone refuse, on enregistre un non : on ne harcèlera pas la personne avec la
  /// boîte système à chaque ouverture.
  Future<bool> repondre(bool oui) async {
    final m = _ref.read(mesureProvider);
    if (!disponible) {
      await _garder(false);
      return false;
    }
    if (!oui) {
      await _garder(false);
      m.suivre('notif_refusee', const {'ou': 'app'});
      return false;
    }
    final perm = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    final ok = perm.authorizationStatus == AuthorizationStatus.authorized ||
        perm.authorizationStatus == AuthorizationStatus.provisional;
    await _garder(ok);
    m.suivre(ok ? 'notif_autorisee' : 'notif_refusee', {'ou': ok ? 'app' : 'systeme'});
    if (ok) await inscrire();
    return ok;
  }

  /// Rouvre la question (réglages du compte).
  Future<void> oublierLeChoix() async {
    _choix = null;
    await _p.remove(_cleChoix);
  }

  /// Désactivation depuis les réglages : le jeton est révoqué chez Google ET retiré chez nous.
  Future<void> desactiver() async {
    final jeton = _jeton ?? await _jetonFcm();
    await _garder(false);
    if (jeton != null) {
      unawaited(_appeler({'action': 'desinscrire', 'jeton': jeton}));
    }
    try {
      if (disponible) await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    _jeton = null;
    _ref.read(mesureProvider).suivre('notif_reglage', const {'valeur': 'desactive'});
  }

  // ── Catégories ────────────────────────────────────────────────────────────────────

  static const categoriesParDefaut = {'soir': true, 'perso': true, 'nouveautes': true, 'acces': true};

  Map<String, bool> get categories {
    try {
      final brut = _p.getString(_cleCats);
      if (brut == null) return Map.of(categoriesParDefaut);
      final d = jsonDecode(brut) as Map<String, dynamic>;
      return {for (final k in categoriesParDefaut.keys) k: d[k] != false};
    } catch (_) {
      return Map.of(categoriesParDefaut);
    }
  }

  Future<void> reglerCategorie(String cle, bool valeur) async {
    final c = categories..[cle] = valeur;
    await _p.setString(_cleCats, jsonEncode(c));
    _ref.read(mesureProvider).suivre('notif_reglage', {'valeur': '$cle:${valeur ? 'on' : 'off'}'});
    if (choix == true) unawaited(inscrire(action: 'profil'));
  }

  // ── Profil d'usage (local) ────────────────────────────────────────────────────────

  Map<String, dynamic> get _u {
    if (_usage != null) return _usage!;
    try {
      _usage = Map<String, dynamic>.from(jsonDecode(_p.getString(_cleUsage) ?? '{}') as Map);
    } catch (_) {
      _usage = <String, dynamic>{};
    }
    _usage!['compteurs'] ??= <String, dynamic>{};
    _usage!['cuisinees'] ??= <dynamic>[];
    _usage!['vues'] ??= <dynamic>[];
    return _usage!;
  }

  Timer? _ecriture;
  void _ecrire() {
    _ecriture?.cancel();
    _ecriture = Timer(const Duration(seconds: 2), () => _p.setString(_cleUsage, jsonEncode(_u)));
  }

  void _compter(String cle) {
    final c = _u['compteurs'] as Map<String, dynamic>;
    c[cle] = ((c[cle] as num?) ?? 0) + 1;
    _ecrire();
  }

  void _empiler(String liste, String slug) {
    final l = (_u[liste] as List).map((e) => e.toString()).toList()..remove(slug)..add(slug);
    _u[liste] = l.length > 30 ? l.sublist(l.length - 30) : l;
    _ecrire();
  }

  /// Branché sur [Mesure.ecoute] : chaque événement de l'app passe ici, consentement GA4 ou
  /// non, et nourrit le profil local. Les noms d'écran sont ceux du routeur.
  void observer(String nom, Map<String, dynamic> params) {
    switch (nom) {
      case 'screen_view':
        final e = params['screen_name']?.toString() ?? '';
        if (e.startsWith('/recipe/')) _empiler('vues', e.substring(8));
        for (final f in const ['frigo', 'favoris', 'programme', 'courses', 'foyer', 'createurs', 'compte']) {
          if (e == '/$f') _compter(f);
        }
      case 'clic':
        final a = params['action']?.toString();
        if (a == 'favori' && params['valeur'] == 'ajoute') _compter('favoris');
        if (a == 'frigo') _compter('frigo');
        if (a == 'courses') _compter('courses');
      case 'recette_ouverte':
        final s = params['recette']?.toString();
        if (s != null && s.isNotEmpty) _empiler('vues', s);
      case 'cuisine_debut':
        _compter('cuisine');
      case 'cuisine_terminee':
        final s = params['slug']?.toString();
        if (s != null) _empiler('cuisinees', s);
      case 'minuteur_lance':
        _compter('minuteur');
    }
    _u['derniere_activite'] = DateTime.now().toIso8601String();
  }

  /// Ce qui part au serveur. Lu dans les fournisseurs au moment de l'envoi : toujours à jour.
  Map<String, dynamic> profil() {
    final favoris = _ref.read(favoritesProvider).toList();
    final frigo = _ref.read(pantryProvider).toList();
    final courses = _ref.read(cartProvider).toList();
    final filtre = _ref.read(recipeFilterProvider);
    final foyer = _ref.read(foyerProvider);
    final compteurs = Map<String, dynamic>.from(_u['compteurs'] as Map);
    return {
      'compteurs': compteurs,
      'favoris': favoris.length > 30 ? favoris.sublist(favoris.length - 30) : favoris,
      'cuisinees': _u['cuisinees'],
      'vues': _u['vues'],
      'frigo': frigo.take(60).toList(),
      'courses': courses.take(60).toList(),
      'regimes': filtre.diets.toList(),
      'repas': filtre.meals.toList(),
      'programme': ((compteurs['programme'] as num?) ?? 0) > 0,
      'foyer': foyer.effectiveCount,
      'heure_habituelle': DateTime.now().hour,
      'derniere_activite': _u['derniere_activite'],
    };
  }

  // ── Inscription ───────────────────────────────────────────────────────────────────

  Future<String?> _jetonFcm() async {
    if (!disponible) return null;
    try {
      return _jeton = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('jeton FCM indisponible : $e');
      return null;
    }
  }

  Future<void> _appeler(Map<String, dynamic> corps) async {
    try {
      await supabase.functions.invoke('push-inscrire', body: corps);
    } catch (e) {
      debugPrint('push-inscrire : $e');
    }
  }

  /// Déclare l'appareil (ou rafraîchit son profil). `action: 'profil'` évite de réécrire la
  /// plateforme et les clés ; le serveur met à jour ce qu'il reçoit.
  Future<void> inscrire({String action = 'inscrire', BuildContext? contexte}) async {
    if (choix != true) return;
    final jeton = await _jetonFcm();
    if (jeton == null) return;
    final langue = _ref.read(langueCatalogueProvider);
    final taille = _ref.read(recipesProvider).asData?.value.length;
    await _appeler({
      'action': action,
      'jeton': jeton,
      'plateforme': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      'langue': langue,
      'fuseau_min': DateTime.now().timeZoneOffset.inMinutes,
      'categories': categories,
      'profil': profil(),
      if (taille != null) 'catalogue': taille,
    });
    await _p.setInt(_cleSync, DateTime.now().millisecondsSinceEpoch);
  }

  /// Au retour au premier plan : le profil part au plus une fois par vingt heures, pour que
  /// le serveur sache ce qui a changé sans que l'app parle à chaque ouverture.
  Future<void> rafraichirSiBesoin() async {
    if (choix != true) return;
    final dernier = _p.getInt(_cleSync) ?? 0;
    if (DateTime.now().millisecondsSinceEpoch - dernier < 20 * 3600 * 1000) return;
    await inscrire(action: 'profil');
  }

  // ── Ouverture ─────────────────────────────────────────────────────────────────────

  /// À appeler une fois le routeur prêt : une notification touchée mène à son écran, que
  /// l'app ait été fermée, en arrière-plan ou ouverte.
  void brancher(GoRouter router) {
    if (!disponible) return;
    FirebaseMessaging.instance.getInitialMessage().then((m) {
      if (m != null) _ouvrir(router, m);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _ouvrir(router, m));
    // Jeton renouvelé par Google : on le redéclare, sinon les envois tombent dans le vide.
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => inscrire());
  }

  void _ouvrir(GoRouter router, RemoteMessage m) {
    final route = m.data['route']?.toString() ?? '/';
    final envoi = m.data['envoi']?.toString();
    _ref.read(mesureProvider).suivre('notif_ouverte', {
      'valeur': m.data['modele']?.toString() ?? '',
      'recette': m.data['recette']?.toString() ?? '',
    });
    if (envoi != null && envoi.isNotEmpty) unawaited(_appeler({'action': 'ouverte', 'envoi': envoi}));
    if (route.startsWith('/')) router.go(route);
  }

  /// Initialisation Firebase, avant `runApp`. Bornée : sans réseau ou sans configuration,
  /// l'app démarre quand même — les notifications sont un confort, pas une condition.
  static Future<void> initialiser() async {
    // Android seulement pour l'instant : sur iOS, il manque la clé APNs côté Firebase ; tant
    // qu'elle n'est pas déposée, demander une permission qu'on ne peut pas honorer n'a pas de
    // sens. Le jour venu : GoogleService-Info.plist + clé APNs, et on retire cette ligne.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) { disponible = false; return; }
    try {
      await Firebase.initializeApp().timeout(const Duration(seconds: 6));
      FirebaseMessaging.onBackgroundMessage(_enArrierePlan);
      disponible = true;
    } catch (e) {
      disponible = false;
      debugPrint('Firebase indisponible : $e');
    }
  }
}

/// Reçu quand l'app est fermée. FCM affiche lui-même la notification (charge `notification`
/// du message) ; il n'y a rien à faire ici, et surtout rien à charger : ce code tourne dans un
/// isolat séparé, sans Riverpod ni Supabase.
@pragma('vm:entry-point')
Future<void> _enArrierePlan(RemoteMessage message) async {}

final notificationsProvider = Provider<Notifications>((ref) {
  final n = Notifications(ref.watch(prefsProvider), ref);
  ref.watch(mesureProvider).ecoute = n.observer;
  return n;
});
