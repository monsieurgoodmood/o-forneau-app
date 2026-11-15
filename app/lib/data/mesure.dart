import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth.dart';
import 'supabase_client.dart';

/// Mesure d'usage de l'app — écrans, actions, temps passé.
///
/// ─── Le consentement passe avant, et il est tenu ici ────────────────────────────────
///
/// Rien ne part tant que la personne n'a pas dit oui. Ce n'est pas un réglage qu'on
/// pourrait oublier d'appliquer : [_envoyer] ne fait rien si [consentement] n'est pas
/// `true`, et la fonction serveur refuse une seconde fois. Un refus efface aussi la file
/// d'attente : ce qui a été observé avant la réponse n'est jamais rattrapé.
///
/// ─── Pourquoi pas Firebase ──────────────────────────────────────────────────────────
///
/// Les événements passent par notre Edge Function `mesure`, qui les relaie à GA4. Le
/// secret d'API reste donc côté serveur, aucun kit Google n'entre dans le binaire, et
/// l'app ne parle qu'à nos serveurs. En échange, GA4 ne fabrique plus `session_start` ni
/// le temps d'engagement : c'est ce fichier qui les produit.
///
/// ─── Ce qui ne part jamais ──────────────────────────────────────────────────────────
///
/// Ni e-mail, ni prénom, ni identifiant de compte, ni texte écrit par l'utilisateur. Le
/// `client_id` est tiré au hasard sur l'appareil et n'a aucun lien avec le compte : on
/// mesure des usages, pas des personnes.
class Mesure {
  static const _cleConsent = 'mf_consent';
  static const _cleClient = 'mf_mid';
  static const _dureeChoix = Duration(days: 182);

  /// Au-delà de trente minutes sans rien faire, c'est une nouvelle visite — la convention
  /// de GA4, reprise ici pour que les durées restent comparables.
  static const _inactiviteSession = Duration(minutes: 30);

  final SharedPreferences _p;
  Mesure(this._p);

  bool? _consent;
  String? _client;
  String? _session;
  DateTime _derniereActivite = DateTime.fromMillisecondsSinceEpoch(0);

  final List<Map<String, dynamic>> _file = [];
  Timer? _vidage;

  /// Écoute LOCALE des événements, indépendante du consentement GA4 : le profil d'usage des
  /// notifications s'en nourrit sans que rien ne quitte l'appareil (voir notifications.dart).
  void Function(String nom, Map<String, dynamic> params)? ecoute;

  String? _ecranCourant;
  DateTime? _debutEcran;

  // ── Consentement ──────────────────────────────────────────────────────────────────

  /// `true` accepté, `false` refusé, `null` pas encore répondu (ou réponse périmée).
  bool? get consentement {
    if (_consent != null) return _consent;
    try {
      final brut = _p.getString(_cleConsent);
      if (brut == null) return null;
      final d = jsonDecode(brut) as Map<String, dynamic>;
      final quand = DateTime.fromMillisecondsSinceEpoch((d['t'] as num).toInt());
      if (DateTime.now().difference(quand) > _dureeChoix) return null;
      return _consent = d['ok'] == true;
    } catch (_) {
      return null;
    }
  }

  Future<void> repondre(bool accepte) async {
    _consent = accepte;
    await _p.setString(_cleConsent, jsonEncode({'ok': accepte, 't': DateTime.now().millisecondsSinceEpoch}));
    if (accepte) {
      _demarrerSession();
      suivre('premiere_ouverture_mesuree');
      unawaited(_vider());
    } else {
      _file.clear(); // ce qui a été observé avant la réponse n'est jamais rattrapé
    }
  }

  /// Rouvre la question (lien « Revenir sur mon choix » de l'écran Compte).
  Future<void> oublierLeChoix() async {
    _consent = null;
    await _p.remove(_cleConsent);
  }

  // ── Identité technique ────────────────────────────────────────────────────────────

  String get _clientId {
    final existant = _client ?? _p.getString(_cleClient);
    if (existant != null && existant.isNotEmpty) return _client = existant;
    // Format attendu par GA4 : deux nombres séparés d'un point.
    final r = Random.secure();
    final neuf = '${100000000 + r.nextInt(899999999)}.${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    _p.setString(_cleClient, neuf);
    return _client = neuf;
  }

  void _demarrerSession() {
    _session = '${DateTime.now().millisecondsSinceEpoch ~/ 1000}';
    _derniereActivite = DateTime.now();
    _ajouter('session_start', const {});
  }

  void _toucher() {
    final maintenant = DateTime.now();
    if (_session == null || maintenant.difference(_derniereActivite) > _inactiviteSession) {
      _demarrerSession();
    }
    _derniereActivite = maintenant;
  }

  // ── Émission ──────────────────────────────────────────────────────────────────────

  static final _interdits = RegExp(
      r'e?mail|prenom|firstname|lastname|user_?id|uid|token|phone|tel|adresse|address|password|secret',
      caseSensitive: false);

  Map<String, dynamic> _nettoyer(Map<String, dynamic>? p) {
    final out = <String, dynamic>{};
    if (p == null) return out;
    for (final e in p.entries) {
      if (_interdits.hasMatch(e.key)) continue;
      final v = e.value;
      if (v == null) continue;
      out[e.key] = v is String ? (v.length > 100 ? v.substring(0, 100) : v) : v;
    }
    return out;
  }

  void _ajouter(String nom, Map<String, dynamic> params) {
    if (_file.length >= 60) _file.removeAt(0); // on garde les plus récents
    _file.add({'name': nom, 'params': params});
  }

  /// Un événement nommé. Sans consentement, il n'est ni envoyé ni conservé durablement.
  void suivre(String nom, [Map<String, dynamic>? params]) {
    try { ecoute?.call(nom, params ?? const {}); } catch (_) {}
    if (consentement == false) return;
    _toucher();
    _ajouter(nom, _nettoyer(params));
    if (consentement == true) _programmerVidage();
  }

  /// Un écran affiché. Le temps passé sur le précédent part au même moment.
  void ecran(String nom) {
    if (nom == _ecranCourant) return;
    _finirEcran();
    _ecranCourant = nom;
    _debutEcran = DateTime.now();
    suivre('screen_view', {'screen_name': nom});
  }

  void _finirEcran() {
    final debut = _debutEcran;
    final nom = _ecranCourant;
    if (debut == null || nom == null) return;
    final ms = DateTime.now().difference(debut).inMilliseconds;
    _debutEcran = null;
    // Sous deux secondes, c'est un passage, pas une lecture.
    if (ms < 2000) return;
    suivre('temps_ecran', {
      'ecran': nom,
      'secondes': (ms / 1000).round(),
      'engagement_time_msec': min(ms, const Duration(minutes: 30).inMilliseconds),
    });
  }

  /// À appeler quand l'app passe en arrière-plan : sinon le dernier écran n'est jamais compté.
  void miseEnPause() {
    _finirEcran();
    unawaited(_vider());
  }

  void _programmerVidage() {
    // On groupe : un envoi par lot plutôt qu'un appel réseau par clic.
    _vidage?.cancel();
    _vidage = Timer(const Duration(seconds: 8), () => unawaited(_vider()));
  }

  Future<void> _vider() async {
    _vidage?.cancel();
    if (consentement != true || _file.isEmpty) return;
    final lot = List<Map<String, dynamic>>.from(_file.take(25));
    _file.removeRange(0, lot.length);
    try {
      await supabase.functions.invoke('mesure', body: {
        'client_id': _clientId,
        'session_id': _session,
        'consentement': true,
        'events': lot,
      });
    } catch (_) {
      // Une mesure perdue n'est pas un incident : on ne réessaie pas indéfiniment et on ne
      // dérange jamais la personne qui cuisine avec un message d'erreur.
    }
  }
}

final mesureProvider = Provider<Mesure>((ref) => Mesure(ref.watch(prefsProvider)));

/// Suit automatiquement chaque écran poussé ou dépilé.
///
/// À brancher sur `observers` du routeur : tout nouvel écran est alors mesuré sans qu'on
/// ait à y penser, ce qui évite la dérive habituelle où la moitié des écrans finit par ne
/// plus être instrumentée parce que personne n'y a pensé en l'ajoutant.
class ObservateurEcrans extends NavigatorObserver {
  final Mesure _m;
  ObservateurEcrans(this._m);

  /// go_router pose le chemin dans `settings.name` ; sans nom, on prend le type de route,
  /// qui reste stable et lisible dans un rapport.
  String _nom(Route<dynamic>? r) {
    if (r == null) return 'inconnu';
    final n = r.settings.name;
    if (n != null && n.isNotEmpty) return n;
    return r.runtimeType.toString().replaceAll(RegExp(r'<[^>]*>'), '');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _m.ecran(_nom(route));

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _m.ecran(_nom(previousRoute));

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => _m.ecran(_nom(newRoute));
}
