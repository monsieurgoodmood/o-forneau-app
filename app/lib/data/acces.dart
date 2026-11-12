import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'auth.dart';
import 'supabase_client.dart';

/// Accès à l'application : 12 mois offerts aux clients Forneau, 1 mois d'essai, puis abonnement.
/// La vérité vient TOUJOURS du serveur (table `acces`, alimentée par les Edge Functions et le
/// webhook RevenueCat) : l'app ne décide jamais seule qu'un accès est valide.

enum AccesSource { shopify, trial, apple, google, manual, aucun }

class Acces {
  final AccesSource source;
  final String state;
  final DateTime? expiresAt;
  const Acces({required this.source, required this.state, this.expiresAt});

  static const aucun = Acces(source: AccesSource.aucun, state: 'expired');

  bool get actif =>
      state != 'expired' && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
  bool get estClient => source == AccesSource.shopify;
  bool get estEssai => source == AccesSource.trial;
  bool get estAbonne => source == AccesSource.apple || source == AccesSource.google;

  int get joursRestants {
    if (expiresAt == null) return 9999;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  factory Acces.fromRow(Map<String, dynamic> r) => Acces(
        source: AccesSource.values.firstWhere(
            (s) => s.name == (r['source']?.toString() ?? ''),
            orElse: () => AccesSource.aucun),
        state: r['state']?.toString() ?? 'expired',
        expiresAt: r['expires_at'] == null ? null : DateTime.tryParse(r['expires_at'].toString()),
      );
}

/// Accès de l'utilisateur connecté. Un invité n'a jamais d'accès premium.
final accesProvider = FutureProvider<Acces>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Acces.aucun;
  try {
    final row = await supabase
        .from('acces')
        .select('source,state,expires_at')
        .eq('user_id', user.id)
        .maybeSingle();
    if (row == null) return Acces.aucun;
    return Acces.fromRow(Map<String, dynamic>.from(row));
  } catch (_) {
    return Acces.aucun;
  }
});

/// Raccourci synchrone pour verrouiller une fonction premium.
final estPremiumProvider = Provider<bool>((ref) {
  final a = ref.watch(accesProvider).asData?.value;
  return a?.actif ?? false;
});

/// Résultat d'une réclamation de commande.
class ResultatCommande {
  final String? erreur;
  final int mois;
  final bool dejaReclamee;
  final int? prochainSeuil;
  final int? prochainMois;
  const ResultatCommande({this.erreur, this.mois = 0, this.dejaReclamee = false,
      this.prochainSeuil, this.prochainMois});
  bool get ok => erreur == null;
}

/// Paliers affichés dans l'app (doivent refléter ceux de la fonction `claim-order`).
const kPaliers = [(70, 3), (100, 6), (150, 12)];

/// Actions d'accès : réclamer une commande, lancer l'essai, acheter, restaurer.
class AccesActions {
  AccesActions(this.ref);
  final Ref ref;

  Future<void> _rafraichir() async {
    ref.invalidate(accesProvider);
    await ref.read(accesProvider.future);
  }

  /// Débloque des mois d'accès selon le montant de la commande (paliers côté serveur).
  /// `erreur` null = succès ; `mois` = ce qui a été accordé ; `prochainSeuil`/`prochainMois`
  /// permettent d'inciter au palier supérieur lors de la prochaine commande.
  Future<ResultatCommande> reclamerCommande({required String numero, required String email}) async {
    try {
      final r = await supabase.functions.invoke('claim-order',
          body: {'order_number': numero, 'email': email});
      final d = (r.data is Map) ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      if (d['ok'] == true) {
        await _rafraichir();
        final p = d['prochain_palier'];
        return ResultatCommande(
          mois: (d['mois_offerts'] as num?)?.toInt() ?? 0,
          dejaReclamee: d['deja_reclamee'] == true,
          prochainSeuil: (p is Map) ? (p['a_partir_de'] as num?)?.toInt() : null,
          prochainMois: (p is Map) ? (p['mois'] as num?)?.toInt() : null,
        );
      }
      return ResultatCommande(erreur: _messageErreur(d['error']?.toString()));
    } catch (e) {
      return ResultatCommande(erreur: _messageErreur(_codeDepuisErreur(e)));
    }
  }

  /// 1 mois d'essai, une seule fois par compte.
  Future<String?> lancerEssai() async {
    try {
      final r = await supabase.functions.invoke('start-trial', body: {});
      final d = (r.data is Map) ? Map<String, dynamic>.from(r.data as Map) : <String, dynamic>{};
      if (d['ok'] == true) {
        await _rafraichir();
        return null;
      }
      return _messageErreur(d['error']?.toString());
    } catch (e) {
      return _messageErreur(_codeDepuisErreur(e));
    }
  }

  String? _codeDepuisErreur(Object e) {
    final s = e.toString();
    for (final c in ['commande_deja_utilisee', 'commande_introuvable', 'essai_deja_utilise',
                     'non_connecte', 'shopify_indisponible']) {
      if (s.contains(c)) return c;
    }
    return null;
  }

  String _messageErreur(String? code) => switch (code) {
        'commande_introuvable' =>
          "Nous ne trouvons pas cette commande. Vérifiez le numéro et l'e-mail utilisé lors de l'achat.",
        'commande_deja_utilisee' =>
          'Cette commande a déjà servi à activer un autre compte.',
        'essai_deja_utilise' => 'Votre mois d’essai a déjà été utilisé.',
        'non_connecte' => 'Connectez-vous pour activer votre accès.',
        'shopify_indisponible' => 'Service momentanément indisponible. Réessayez dans un instant.',
        _ => 'Une erreur est survenue. Réessayez.',
      };

  // ---------- Abonnement (RevenueCat : Apple IAP + Google Play Billing) ----------

  /// Mode vitrine : affiche les forfaits aux tarifs réels sans interroger les boutiques.
  /// Sert uniquement à produire les captures exigées par la revue des stores, là où aucun
  /// achat intégré n'existe (rendu web, machine de build). Absent des binaires publiés :
  /// la constante vaut false sans `--dart-define=VITRINE=true`, et l'arbre mort est élagué.
  static const _vitrine = bool.fromEnvironment('VITRINE');

  List<rc.Package> _forfaitsVitrine() => [
        _paquetVitrine('\$rc_monthly', 'MONTHLY', 'premium_monthly', 3.99, '3,99 €', 'P1M'),
        _paquetVitrine('\$rc_annual', 'ANNUAL', 'premium_yearly', 24.99, '24,99 €', 'P1Y'),
      ];

  rc.Package _paquetVitrine(String id, String type, String sku, double prix, String prixTexte, String periode) =>
      rc.Package.fromJson({
        'identifier': id,
        'packageType': type,
        'presentedOfferingContext': {'offeringIdentifier': 'default', 'placementIdentifier': null, 'targetingContext': null},
        'product': {
          'identifier': sku,
          'title': 'Ô Forneau Premium',
          'description': 'Accès à toutes les fonctions de cuisine',
          'price': prix,
          'priceString': prixTexte,
          'currencyCode': 'EUR',
          'productCategory': 'SUBSCRIPTION',
          'subscriptionPeriod': periode,
        },
      });

  Future<List<rc.Package>> forfaits() async {
    if (_vitrine) return _forfaitsVitrine();
    if (!RevenueCat.disponible) return const [];
    try {
      final current = (await rc.Purchases.getOfferings()).current;
      if (current == null) return const [];
      final out = <rc.Package>[];
      // Mensuel puis annuel, en retombant sur le type puis sur l'identifiant : la config
      // RevenueCat peut utiliser des identifiants personnalisés.
      for (final (typed, type, mots) in [
        (current.monthly, rc.PackageType.monthly, const ['month', 'mensuel']),
        (current.annual, rc.PackageType.annual, const ['annual', 'year', 'annuel']),
      ]) {
        final p = typed ??
            current.availablePackages.where((x) => x.packageType == type).firstOrNull ??
            current.availablePackages
                .where((x) => mots.any(x.identifier.toLowerCase().contains))
                .firstOrNull;
        if (p != null && !out.contains(p)) out.add(p);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Achat. Renvoie null si l'accès est actif ensuite, sinon un message (null aussi si annulé).
  Future<String?> acheter(rc.Package p) async {
    try {
      await rc.Purchases.purchase(rc.PurchaseParams.package(p));
      await _rafraichir();
      return null;
    } on PlatformException catch (e) {
      final code = rc.PurchasesErrorHelper.getErrorCode(e);
      if (code == rc.PurchasesErrorCode.purchaseCancelledError) return null;
      return "L'achat n'a pas abouti. Réessayez.";
    } catch (_) {
      return "L'achat n'a pas abouti. Réessayez.";
    }
  }

  Future<String?> restaurer() async {
    try {
      await rc.Purchases.restorePurchases();
      await _rafraichir();
      return null;
    } catch (_) {
      return 'Aucun achat à restaurer sur ce compte.';
    }
  }
}

final accesActionsProvider = Provider<AccesActions>((ref) => AccesActions(ref));

/// Configuration RevenueCat. L'appUserID est l'UUID du compte Supabase : le webhook `rc-webhook`
/// retrouve ainsi l'utilisateur et écrit son accès. Clés passées au build par --dart-define,
/// jamais en dur dans le binaire.
class RevenueCat {
  RevenueCat._();
  static const _iosKey = String.fromEnvironment('RC_IOS_KEY');
  static const _androidKey = String.fromEnvironment('RC_ANDROID_KEY');
  static bool _pret = false;

  static String? get _cle {
    if (kIsWeb) return null;
    if (Platform.isIOS || Platform.isMacOS) return _iosKey.isEmpty ? null : _iosKey;
    if (Platform.isAndroid) return _androidKey.isEmpty ? null : _androidKey;
    return null;
  }

  /// Vrai si l'achat intégré est utilisable (clé fournie au build + plateforme native).
  static bool get disponible => _pret;

  static Future<void> configurer(String? userId) async {
    final cle = _cle;
    if (cle == null || userId == null) return;
    try {
      if (_pret) {
        await rc.Purchases.logIn(userId);
        return;
      }
      await rc.Purchases.setLogLevel(rc.LogLevel.warn);
      await rc.Purchases.configure(rc.PurchasesConfiguration(cle)..appUserID = userId);
      _pret = true;
    } catch (_) {
      _pret = false;
    }
  }

  static Future<void> deconnecter() async {
    if (!_pret) return;
    try { await rc.Purchases.logOut(); } catch (_) {}
  }
}

extension _First<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
