// L'analyse d'un lien de créateur est la pièce que l'utilisateur sollicite en premier,
// avec du texte collé depuis n'importe quelle app. Elle doit accepter largement et
// refuser clairement, sans jamais enregistrer un pseudo fantaisiste.
import 'package:flutter_test/flutter_test.dart';
import 'package:o_forneau/data/createurs.dart';

void main() {
  group('liens Instagram', () {
    test('profil simple', () {
      final r = analyserLien('https://www.instagram.com/cheftomy/');
      expect(r.valide, isTrue);
      expect(r.plateforme, Plateforme.instagram);
      expect(r.handle, 'cheftomy');
    });

    test('lien de Reel : on remonte au profil', () {
      final r = analyserLien('https://www.instagram.com/cheftomy/reel/C8xYz12AbCd/?igsh=abc');
      expect(r.handle, 'cheftomy');
    });

    test('sans protocole', () {
      expect(analyserLien('instagram.com/ChefTomy').handle, 'cheftomy');
    });

    test('lien de publication sans profil : refusé avec explication', () {
      final r = analyserLien('https://www.instagram.com/p/C8xYz12AbCd/');
      expect(r.valide, isFalse);
      expect(r.erreur, contains('profil'));
    });
  });

  group('liens TikTok', () {
    test('profil', () {
      final r = analyserLien('https://www.tiktok.com/@cheftomy');
      expect(r.plateforme, Plateforme.tiktok);
      expect(r.handle, 'cheftomy');
    });

    test('lien de vidéo', () {
      final r = analyserLien('https://www.tiktok.com/@chef.tomy/video/7312345678901234567');
      expect(r.handle, 'chef.tomy');
    });

    test('lien court sans pseudo : refusé', () {
      expect(analyserLien('https://www.tiktok.com/t/ZT8abcdef/').valide, isFalse);
    });
  });

  group('pseudo seul', () {
    test('prend la plateforme choisie dans l’écran', () {
      final r = analyserLien('@ChefTomy', parDefaut: Plateforme.tiktok);
      expect(r.plateforme, Plateforme.tiktok);
      expect(r.handle, 'cheftomy');
    });

    test('sans plateforme choisie : on demande laquelle', () {
      final r = analyserLien('cheftomy');
      expect(r.valide, isFalse);
      expect(r.erreur, contains('Instagram'));
    });
  });

  group('refus', () {
    test('vide', () => expect(analyserLien('').valide, isFalse));
    test('autre plateforme', () {
      final r = analyserLien('https://youtube.com/@cheftomy');
      expect(r.valide, isFalse);
      expect(r.erreur, contains('Instagram et TikTok'));
    });
    test('pseudo impossible', () {
      expect(analyserLien('chef tomy!', parDefaut: Plateforme.instagram).valide, isFalse);
    });
    test('pseudo trop long', () {
      expect(analyserLien('a' * 31, parDefaut: Plateforme.instagram).valide, isFalse);
    });
  });
}
