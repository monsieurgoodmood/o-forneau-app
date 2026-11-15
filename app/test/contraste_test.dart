// Aucun texte de l'app ne doit être trop pâle pour être lu.
//
// Demandé le 13/11/2026 après avoir vu, sur le mode cuisine du web, un bouton
// « Précédent » écrit en crème sur un fond crème : 1,08:1, invisible. La même faute peut
// se produire ici, et de la même façon — une couleur de texte posée pour un fond, un
// conteneur qui en peint un autre.
//
// On ne juge pas à l'œil : on applique le seuil WCAG AA, celui du RGAA et des deux stores.
// 4,5:1 pour du texte courant, 3:1 au-delà de 24 px (ou 18,7 px en gras), parce qu'un
// grand caractère reste lisible avec moins de contraste.
//
//   flutter test test/contraste_test.dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:o_forneau/core/theme/app_theme.dart';
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
import 'package:o_forneau/l10n/app_localizations.dart';

/// Luminance relative, formule WCAG 2.1.
double _luminance(Color c) {
  double canal(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}

double _contraste(Color texte, Color fond) {
  final a = _luminance(texte), b = _luminance(fond);
  final (haut, bas) = a > b ? (a, b) : (b, a);
  return (haut + 0.05) / (bas + 0.05);
}

/// Compose une couleur translucide sur ce qu'il y a derrière.
Color _poser(Color dessus, Color dessous) => Color.alphaBlend(dessus, dessous);

/// La couleur de fond réellement peinte derrière [depuis].
///
/// Elle n'est presque jamais portée par le widget du texte : on remonte l'arbre de rendu
/// jusqu'au premier fond opaque, en composant les couches translucides au passage. Sans
/// cela, on comparerait un texte au blanc par défaut et on manquerait exactement le cas
/// qu'on cherche — un texte clair posé sur un conteneur clair.
Color _fondDerriere(RenderObject depuis) {
  final couches = <Color>[];
  RenderObject? n = depuis.parent;
  while (n != null) {
    final c = _couleurPeinte(n);
    if (c != null && c.a > 0) {
      couches.add(c);
      if (c.a >= 1.0) break; // opaque : inutile de remonter plus haut
    }
    n = n.parent;
  }
  var fond = const Color(0xFFFFFFFF); // le moteur peint du blanc sous tout
  for (final c in couches.reversed) {
    fond = _poser(c, fond);
  }
  return fond;
}

/// La couleur qu'un objet de rendu peint sur toute sa surface, s'il en peint une.
Color? _couleurPeinte(RenderObject o) {
  if (o is RenderDecoratedBox) {
    final d = o.decoration;
    if (d is BoxDecoration) {
      // Un dégradé est jugé sur sa pire étape : c'est le pixel qu'on va lire dessus.
      if (d.gradient case final g?) {
        final etapes = g.colors;
        if (etapes.isNotEmpty) {
          return etapes.reduce((a, b) => _luminance(a) > _luminance(b) ? a : b);
        }
      }
      return d.color;
    }
    if (d is ShapeDecoration) return d.color;
  }
  if (o is RenderPhysicalShape) return o.color;
  if (o is RenderPhysicalModel) return o.color;
  // ColoredBox passe par un rendu privé : on lit `color` dynamiquement.
  try {
    final dyn = o as dynamic;
    final c = dyn.color;
    if (c is Color) return c;
  } catch (_) {}
  return null;
}

class _Faute {
  final String texte, ecran;
  final double ratio, seuil, taille;
  final Color couleur, fond;
  _Faute(this.ecran, this.texte, this.ratio, this.seuil, this.taille, this.couleur, this.fond);

  @override
  String toString() =>
      '${ratio.toStringAsFixed(2)}:1 (min $seuil) ${taille.round()}px  « $texte »\n'
      '        ${_hex(couleur)} sur ${_hex(fond)}   [$ecran]';

  static String _hex(Color c) =>
      '#${((c.a * 255).round() << 24 | (c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(8, '0').toUpperCase().substring(2)}';
}

List<_Faute> _mesurer(WidgetTester tester, String ecran) {
  final fautes = <_Faute>[];
  final vus = <String>{};
  for (final rp in tester.allRenderObjects.whereType<RenderParagraph>()) {
    if (!rp.attached || rp.size.isEmpty) continue;
    final fond = _fondDerriere(rp);

    rp.text.visitChildren((span) {
      if (span is! TextSpan) return true;
      final mot = span.text?.trim() ?? '';
      if (mot.isEmpty) return true;
      final style = span.style ?? rp.text.style;
      final couleur = style?.color;
      if (couleur == null || couleur.a == 0) return true;

      final taille = style?.fontSize ?? 14;
      final gras = (style?.fontWeight?.index ?? 3) >= FontWeight.w700.index;
      final seuil = (taille >= 24 || (gras && taille >= 18.66)) ? 3.0 : 4.5;

      final devant = couleur.a < 1 ? _poser(couleur, fond) : couleur;
      final r = _contraste(devant, fond);
      if (r >= seuil) return true;

      // Une même paire couleur/fond ne se signale qu'une fois par écran.
      final cle = '$ecran|${_Faute._hex(couleur)}|${_Faute._hex(fond)}|${taille.round()}';
      if (!vus.add(cle)) return true;
      fautes.add(_Faute(ecran, mot.length > 40 ? '${mot.substring(0, 40)}…' : mot,
          r, seuil, taille, couleur, fond));
      return true;
    });
  }
  return fautes;
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initSupabase();
  });

  final ecrans = <String, Widget Function()>{
    'Programme': () => const ProgrammeScreen(),
    'Foyer': () => const FoyerScreen(),
    'Abonnement': () => const PaywallScreen(fonction: 'Le mode cuisine'),
    'Commande': () => const ClaimOrderScreen(),
    'Créer un compte': () => const InvitationCompteScreen(fonction: 'Le mode cuisine'),
    'Créateurs': () => const CreateursScreen(),
    'Compte': () => const AccountScreen(),
    // La fenêtre de consentement à la mesure entre dans les contrôles comme un écran :
    // c'est la première chose que voit un nouvel utilisateur, et elle porte deux boutons
    // dont l'un ne doit surtout pas être moins lisible que l'autre.
    'Consentement mesure': () => const Scaffold(body: ConsentementMesure()),
  };

  for (final entree in ecrans.entries) {
    testWidgets('${entree.key} se lit — contraste WCAG AA', (tester) async {
      tester.view.physicalSize = const ui.Size(390 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: L.localizationsDelegates,
          supportedLocales: L.supportedLocales,
          home: entree.value(),
        ),
      ));
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        tester.takeException();
      }

      final fautes = _mesurer(tester, entree.key);
      expect(fautes, isEmpty,
          reason: '\nTextes trop pâles sur « ${entree.key} » :\n\n'
              '${fautes.map((f) => '  $f').join('\n\n')}\n');
    });
  }
}
