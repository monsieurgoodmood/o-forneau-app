// Produit les captures des écrans d'accès exigées par la revue des stores.
//
//   flutter test test/captures_test.dart --update-goldens --dart-define=VITRINE=true
//
// On passe par le moteur de test plutôt que par un appareil ou un navigateur : il rend le
// VRAI arbre de widgets, avec le vrai thème et les vraies polices, et écrit un PNG. Le mode
// vitrine (--dart-define=VITRINE) fournit les forfaits aux tarifs réels sans interroger
// Apple ni Google, qui n'existent pas dans un test.
//
// Les polices sont chargées depuis test/fonts/ et NON téléchargées : le moteur de test coupe
// le réseau, et laisser google_fonts tenter sa requête bloque le test jusqu'à expiration.
// Les noms de familles suivent la convention de google_fonts (`Famille_variante`), sinon le
// rendu retombe silencieusement sur la police par défaut.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:o_forneau/core/theme/app_theme.dart';
import 'package:o_forneau/data/auth.dart';
import 'package:o_forneau/data/supabase_client.dart';
import 'package:o_forneau/features/acces/claim_order_screen.dart';
import 'package:o_forneau/features/acces/paywall_screen.dart';

const _largeur = 390.0; // iPhone 14/15
const _densite = 3.0;
// MaterialIcons doit être chargée explicitement : sans elle, chaque icône sort en carré vide.
const _polices = {
  'Inter_regular': 'Inter_regular',
  'Inter_500': 'Inter_500',
  'Inter_600': 'Inter_600',
  'Inter_700': 'Inter_700',
  'PlayfairDisplay_700': 'PlayfairDisplay_700',
  'MaterialIcons': 'MaterialIcons',
};

Future<void> _chargerPolices() async {
  for (final entree in _polices.entries) {
    final octets = File('test/fonts/${entree.value}.ttf').readAsBytesSync();
    final chargeur = FontLoader(entree.key)..addFont(Future.value(ByteData.sublistView(octets)));
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
    child: MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(key: cle, child: ecran),
    ),
  ));

  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  if (defilement > 0) {
    await tester.drag(find.byType(ListView).first, Offset(0, -defilement));
    await tester.pumpAndSettle();
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
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
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

  testWidgets('commande', (tester) async {
    await _capturer(tester, const ClaimOrderScreen(), 'commande', hauteur: 1200);
  });
}
