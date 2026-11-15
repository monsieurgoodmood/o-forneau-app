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
import 'package:shared_preferences/shared_preferences.dart';

import 'package:o_forneau/core/theme/app_theme.dart';
import 'package:o_forneau/l10n/app_localizations.dart';
import 'package:o_forneau/data/auth.dart';
import 'package:o_forneau/data/supabase_client.dart';
import 'package:o_forneau/features/acces/claim_order_screen.dart';
import 'package:o_forneau/features/acces/paywall_screen.dart';
import 'package:o_forneau/features/auth/account_screen.dart';
import 'package:o_forneau/features/auth/exiger_compte.dart';
import 'package:o_forneau/features/createurs/createurs_screen.dart';
import 'package:o_forneau/features/mesure/consentement_mesure.dart';
import 'package:o_forneau/features/programme/foyer_screen.dart';
import 'package:o_forneau/features/programme/programme_screen.dart';

/// iPhone SE, iPhone 14, et la largeur CSS de l'audit après zoom.
const _largeurs = <(double, String)>[(320, 'iPhone SE'), (390, 'iPhone 14'), (454, 'audit')];

/// Les vraies polices de l'app, chargées sous leurs vraies familles.
///
/// Elles étaient lues depuis `test/fonts/` sous les noms internes que `google_fonts`
/// fabriquait à l'exécution (`Inter_600`). Les polices sont maintenant embarquées dans
/// `assets/fonts/` sous les familles « Inter » et « Playfair Display » : le test lit les
/// mêmes fichiers que l'app et mesure donc les mêmes largeurs de texte. Charger une
/// famille que l'app n'utilise pas rendrait ce test aveugle aux débordements, puisqu'il
/// mesurerait une police de secours plus étroite que celle qui s'affiche.
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

/// Pompe l'écran et rend la liste des débordements rencontrés.
Future<List<String>> _debordements(WidgetTester tester, Widget ecran, double largeur) async {
  tester.view.physicalSize = ui.Size(largeur * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    // Les traductions doivent être déclarées comme dans l'app : sans elles,
    // `L.of(context)` renvoie null, chaque écran qui lit un libellé lève une erreur à la
    // construction, et le test mesure la mise en page d'un écran d'erreur rouge au lieu de
    // l'écran réel. Il passait alors sans rien vérifier.
    child: MaterialApp(
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      home: ecran,
    ),
  ));

  final fautes = <String>[];
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    final e = tester.takeException();
    if (e == null) continue;
    // Toute exception compte, pas seulement les débordements. Ne retenir que
    // « overflowed » revenait à déclarer verts des écrans qui n'arrivaient même pas à se
    // construire : un test qui avale les erreurs est pire qu'un test absent.
    fautes.add(e.toString().split('\n').first);
  }
  return fautes;
}

void main() {
  setUpAll(() async {
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
    // Ajouté le 13/11/2026 avec le bouton « Télécharger mes données » : tout écran qu'on
    // touche entre dans ce test, sinon la couverture se périme sans qu'on le voie.
    'Compte': () => const AccountScreen(),
    // La fenêtre de consentement à la mesure entre dans les contrôles comme un écran :
    // c'est la première chose que voit un nouvel utilisateur, et elle porte deux boutons
    // dont l'un ne doit surtout pas être moins lisible que l'autre.
    'Consentement mesure': () => const Scaffold(body: ConsentementMesure()),
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
