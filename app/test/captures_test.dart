// Produit les captures des écrans d'accès exigées par la revue des stores.
//
//   flutter test test/captures_test.dart --timeout=none --dart-define=VITRINE=true
//
// ⏱️ COMPTER ENVIRON SEPT MINUTES PAR CAPTURE sur cette machine, soit ~45 min pour les six.
// `toImage(pixelRatio: 3)` rastérise 4 à 5 mégapixels en logiciel, sans GPU. Avec un délai
// d'expiration trop court, la capture s'écrit puis le test est tué juste avant de se
// déclarer réussi : on lit « did not complete » et on croit à un blocage alors que c'est
// seulement lent. Toujours passer `--timeout=none`, et ne jamais lancer deux `flutter test`
// en parallèle — ils se battent pour la RAM et aucun ne finit.
//
// On passe par le moteur de test plutôt que par un appareil ou un navigateur : il rend le
// VRAI arbre de widgets, avec le vrai thème et les vraies polices, et écrit un PNG. Le mode
// vitrine (--dart-define=VITRINE) fournit les forfaits aux tarifs réels sans interroger
// Apple ni Google, qui n'existent pas dans un test.
//
// Les polices sont lues dans assets/fonts/, exactement les fichiers que l'app embarque, et
// chargées sous leurs vraies familles (« Inter », « Playfair Display »). Une famille que
// l'app n'utilise pas ferait retomber le rendu sur la police par défaut sans rien dire : la
// capture envoyée à Apple ne montrerait alors pas l'app telle qu'elle s'affiche.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:o_forneau/core/theme/app_theme.dart';
import 'package:o_forneau/l10n/app_localizations.dart';
import 'package:o_forneau/data/auth.dart';
import 'package:o_forneau/data/supabase_client.dart';
import 'package:o_forneau/features/acces/claim_order_screen.dart';
import 'package:o_forneau/features/acces/paywall_screen.dart';
import 'package:o_forneau/features/auth/exiger_compte.dart';
import 'package:o_forneau/features/createurs/createurs_screen.dart';
import 'package:o_forneau/features/programme/programme_screen.dart';

const _largeur = 390.0; // iPhone 14/15
const _densite = 3.0;
// MaterialIcons doit être chargée explicitement : sans elle, chaque icône sort en carré vide.
const _polices = <String, List<String>>{
  'Inter': [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ],
  'Playfair Display': ['assets/fonts/PlayfairDisplay-Bold.ttf'],
  'MaterialIcons': ['test/fonts/MaterialIcons.ttf'],
};

Future<void> _chargerPolices() async {
  for (final entree in _polices.entries) {
    final chargeur = FontLoader(entree.key);
    for (final chemin in entree.value) {
      final octets = File(chemin).readAsBytesSync();
      chargeur.addFont(Future.value(ByteData.sublistView(octets)));
    }
    await chargeur.load();
  }
}

/// [hauteur] : on rend l'écran dans une fenêtre assez haute pour contenir toute la page,
/// de sorte que la capture montre les forfaits et leurs prix — ce que la revue Apple exige.
Future<void> _capturer(WidgetTester tester, Widget ecran, String nom,
    {double hauteur = 844, double defilement = 0}) async {
  tester.view.physicalSize = Size(_largeur * _densite, hauteur * _densite);
  tester.view.devicePixelRatio = _densite;
  addTearDown(tester.view.reset);

  final cle = GlobalKey();
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    // Les traductions doivent être déclarées comme dans l'app. Sans elles,
    // `L.of(context)` renvoie null et chaque écran qui lit un libellé lève une erreur :
    // la capture envoyée à Apple montrait un écran d'erreur, pas l'app.
    child: MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: RepaintBoundary(key: cle, child: ecran),
    ),
  ));

  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  if (defilement > 0) {
    await tester.drag(find.byType(ListView).first, Offset(0, -defilement));
    // Pompage borné, jamais `pumpAndSettle()`. Un écran qui attend une réponse qu'un test
    // ne donnera pas — l'abonnement, qui tourne en attendant les offres du magasin —
    // garde une animation en cours indéfiniment, et `pumpAndSettle()` ne rend alors jamais
    // la main : le test ne tombait pas en échec, il restait suspendu jusqu'à ce qu'on le
    // tue. Deux secondes suffisent à poser le défilement.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  // On photographie nous-mêmes plutôt que par matchesGoldenFile : celui-ci écrit en taille
  // logique (390 px de large), alors qu'Apple refuse toute capture sous 640 px.
  final surface = cle.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await surface.toImage(pixelRatio: _densite);
  final octets = await image.toByteData(format: ui.ImageByteFormat.png);
  final fichier = File('test/captures/$nom.png')..parent.createSync(recursive: true);
  fichier.writeAsBytesSync(octets!.buffer.asUint8List());
  // ignore: avoid_print
  print('capture $nom : ${image.width}x${image.height} px → ${fichier.path}');
  // Libérer la ressource natale après en avoir lu les dimensions, pas avant.
  image.dispose();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    // ClaimOrderScreen lit le compte courant dès initState : sans client Supabase, l'écran
    // ne se construit pas du tout. L'initialisation ne fait aucun appel réseau.
    await initSupabase();
    await _chargerPolices();
  });

  testWidgets('abonnement', (tester) async {
    await _capturer(tester, const PaywallScreen(fonction: 'Le mode cuisine'), 'abonnement',
        hauteur: 1500);
  });

  // Format iPhone exact (1170 x 2532), défilé jusqu'aux forfaits : c'est la capture que
  // réclame la revue des abonnements Apple, qui veut voir les options d'achat.
  testWidgets('abonnement-forfaits', (tester) async {
    await _capturer(tester, const PaywallScreen(fonction: 'Le mode cuisine'), 'abonnement-forfaits',
        defilement: 620);
  });

  testWidgets('compte', (tester) async {
    await _capturer(tester, const InvitationCompteScreen(fonction: 'Le mode cuisine'), 'compte',
        hauteur: 1000);
  });

  testWidgets('createurs', (tester) async {
    await _capturer(tester, const CreateursScreen(), 'createurs', hauteur: 1100);
  });

  testWidgets('programme', (tester) async {
    await _capturer(tester, const ProgrammeScreen(), 'programme', hauteur: 1400);
  });

  testWidgets('commande', (tester) async {
    await _capturer(tester, const ClaimOrderScreen(), 'commande', hauteur: 1200);
  });
}
