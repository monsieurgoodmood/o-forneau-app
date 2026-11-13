// Le minuteur du mode cuisine est utilisé les mains sales, en confiance. S'il repart à
// zéro ou s'il prend du retard en silence, la personne rate sa cuisson sans comprendre.
// Reprend les critères du ticket A09.
import 'package:flutter_test/flutter_test.dart';
import 'package:o_forneau/features/recipes/minuteur.dart';

/// Horloge pilotée : on avance le temps sans attendre.
class Horloge {
  DateTime t = DateTime(2026, 11, 13, 8, 0, 0);
  DateTime lire() => t;
  void avance(Duration d) => t = t.add(d);
}

void main() {
  late Horloge h;
  late MinuteurEtape m;

  setUp(() {
    h = Horloge();
    m = MinuteurEtape(horloge: h.lire);
  });

  group('décompte', () {
    test('au lancement, il reste la durée demandée', () {
      m.lancer(600, 1);
      expect(m.restant, 600);
      expect(m.arme, isTrue);
      expect(m.etape, 1);
    });

    test('le temps passe', () {
      m.lancer(600, 1);
      h.avance(const Duration(seconds: 90));
      expect(m.restant, 510);
    });

    test('il ne descend jamais sous zéro', () {
      m.lancer(10, 0);
      h.avance(const Duration(minutes: 5));
      expect(m.restant, 0);
      expect(m.termine, isTrue);
    });

    test('une durée nulle ou négative n’arme rien', () {
      m.lancer(0, 1);
      expect(m.arme, isFalse);
    });
  });

  group('A09 — le minuteur survit à la navigation', () {
    test('changer d’étape ne l’arrête pas', () {
      m.lancer(600, 1);
      h.avance(const Duration(seconds: 60));
      // L'écran passe à l'étape 2 puis revient à l'étape 1 : rien n'est touché.
      expect(m.restant, 540);
      expect(m.ailleurs(2), isTrue, reason: 'il tourne pour l’étape 1');
      expect(m.ailleurs(1), isFalse, reason: 'on est revenu sur son étape');
    });

    test('le téléphone verrouillé ne fait pas dériver le décompte', () {
      m.lancer(600, 1);
      // L'app dort dix minutes : un décompte à base de battements aurait pris dix
      // minutes de retard. Une échéance, non.
      h.avance(const Duration(minutes: 10));
      expect(m.restant, 0);
      expect(m.termine, isTrue);
    });
  });

  group('pause', () {
    test('la pause conserve le temps restant', () {
      m.lancer(600, 1);
      h.avance(const Duration(seconds: 100));
      m.pause();
      expect(m.enPause, isTrue);
      h.avance(const Duration(minutes: 30)); // on discute, on cherche un ustensile
      expect(m.restant, 500, reason: 'une pause arrête vraiment le temps');
    });

    test('la reprise repart du temps conservé', () {
      m.lancer(600, 1);
      h.avance(const Duration(seconds: 100));
      m.pause();
      h.avance(const Duration(minutes: 30));
      m.reprendre();
      expect(m.enPause, isFalse);
      expect(m.restant, 500);
      h.avance(const Duration(seconds: 200));
      expect(m.restant, 300);
    });

    test('reprendre sans pause ne fait rien', () {
      m.reprendre();
      expect(m.arme, isFalse);
    });
  });

  group('arrêt', () {
    test('tout est remis à zéro', () {
      m.lancer(600, 2);
      m.arreter();
      expect(m.arme, isFalse);
      expect(m.etape, isNull);
      expect(m.restant, 0);
    });
  });

  group('relance', () {
    test('relancer remplace le minuteur en cours', () {
      m.lancer(600, 1);
      h.avance(const Duration(seconds: 300));
      m.lancer(120, 3);
      expect(m.restant, 120);
      expect(m.etape, 3);
    });
  });
}
