// Aucun écran ne doit déborder horizontalement.
//
// Signalé le 13/11/2026 sur l'écran Programme : les choix d'objectif et de type
// d'alimentation vivaient dans des listes horizontales de cartes à largeur figée.
// Sur un téléphone, le dernier choix était coupé net au bord de l'écran et rien
// n'indiquait qu'il fallait faire glisser. Flutter signale ce genre de faute par une
// exception de rendu : ce test la transforme en échec, à trois largeurs réelles.
//
//   flutter test test/debordement_test.dart --dart-define=VITRINE=true
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
import 'package:o_forneau/features/auth/exiger_compte.dart';
import 'package:o_forneau/features/createurs/createurs_screen.dart';
import 'package:o_forneau/features/programme/foyer_screen.dart';
import 'package:o_forneau/features/programme/programme_screen.dart';

/// iPhone SE, iPhone 14, et la largeur CSS de l'audit après zoom.
const _largeurs = <(double, String)>[(320, 'iPhone SE'), (390, 'iPhone 14'), (454, 'audit')];

const _polices = ['Inter_regular', 'Inter_500', 'Inter_600', 'Inter_700',
                  'PlayfairDisplay_700', 'MaterialIcons'];

Future<void> _chargerPolices() async {
  for (final nom in _polices) {
    final octets = File('test/fonts/$nom.ttf').readAsBytesSync();
    await (FontLoader(nom)..addFont(Future.value(ByteData.sublistView(octets)))).load();
  }
}

/// Pompe l'écran et rend la liste des débordements rencontrés.
Future<List<String>> _debordements(WidgetTester tester, Widget ecran, double largeur) async {
  tester.view.physicalSize = ui.Size(largeur * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(theme: AppTheme.light, debugShowCheckedModeBanner: false, home: ecran),
  ));

  final fautes = <String>[];
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    final e = tester.takeException();
    if (e != null && e.toString().contains('overflowed')) {
      fautes.add(e.toString().split('\n').first);
    }
  }
  return fautes;
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await initSupabase();
    await _chargerPolices();
  });

  final ecrans = <String, Widget Function()>{
    'Programme': () => const ProgrammeScreen(),
    'Foyer': () => const FoyerScreen(),
    'Abonnement': () => const PaywallScreen(fonction: 'Le mode cuisine'),
    'Commande': () => const ClaimOrderScreen(),
    'Créer un compte': () => const InvitationCompteScreen(fonction: 'Le mode cuisine'),
    'Créateurs': () => const CreateursScreen(),
  };

  for (final entree in ecrans.entries) {
    for (final (largeur, appareil) in _largeurs) {
      testWidgets('${entree.key} ne déborde pas à ${largeur.toInt()} px ($appareil)', (tester) async {
        final fautes = await _debordements(tester, entree.value(), largeur);
        expect(fautes, isEmpty, reason: fautes.join(' | '));
      });
    }
  }
}
