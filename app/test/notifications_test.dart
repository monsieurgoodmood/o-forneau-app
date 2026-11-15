import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:o_forneau/data/auth.dart';
import 'package:o_forneau/data/mesure.dart';
import 'package:o_forneau/data/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le profil d'usage et le consentement des notifications, sans réseau ni Firebase :
/// ce qui se décide sur l'appareil doit se vérifier sur l'appareil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> conteneur([Map<String, Object> prefs = const {}]) async {
    Notifications.disponible = true; // comme sur un Android configuré ; sans transport, tout est muet
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    return ProviderContainer(overrides: [prefsProvider.overrideWithValue(p)]);
  }

  test('la question ne se pose qu’à partir de la deuxième session', () async {
    final c = await conteneur();
    final n = c.read(notificationsProvider);
    expect(n.choix, isNull);
    expect(n.aDemander, isFalse, reason: 'première session : on laisse voir l’app');
    await n.compterSession();
    await n.compterSession();
    expect(n.aDemander, isTrue);
  });

  test('un refus est retenu et ne redemande pas', () async {
    final c = await conteneur({'mf_sessions': 5});
    final n = c.read(notificationsProvider);
    expect(n.aDemander, isTrue);
    final ok = await n.repondre(false);
    expect(ok, isFalse);
    expect(n.choix, isFalse);
    expect(n.aDemander, isFalse);
    await n.oublierLeChoix();
    expect(n.aDemander, isTrue, reason: 'revenir sur son choix rouvre la question');
  });

  test('les catégories se règlent et se relisent', () async {
    final c = await conteneur();
    final n = c.read(notificationsProvider);
    expect(n.categories, Notifications.categoriesParDefaut);
    await n.reglerCategorie('soir', false);
    expect(n.categories['soir'], isFalse);
    expect(n.categories['perso'], isTrue);
  });

  test('le profil d’usage se nourrit des événements de la mesure, sans consentement GA4', () async {
    final c = await conteneur();
    final n = c.read(notificationsProvider);
    final m = c.read(mesureProvider);
    expect(m.consentement, isNull);
    m.ecran('/frigo');
    m.ecran('/recipe/Dej93ljjjJA');
    m.suivre('clic', {'action': 'favori', 'valeur': 'ajoute', 'recette': 'Dej93ljjjJA'});
    m.suivre('cuisine_debut', {'slug': 'Dej93ljjjJA'});
    m.suivre('cuisine_terminee', {'slug': 'Dej93ljjjJA', 'etape': 8, 'sur': 8});
    final p = n.profil();
    final compteurs = p['compteurs'] as Map;
    expect(compteurs['frigo'], 1);
    expect(compteurs['favoris'], 1);
    expect(compteurs['cuisine'], 1);
    expect(p['vues'], contains('Dej93ljjjJA'));
    expect(p['cuisinees'], contains('Dej93ljjjJA'));
    expect(p['programme'], isFalse);
    expect(p.keys, isNot(anyOf(contains('email'), contains('prenom'))));
  });

  test('les listes du profil sont bornées à trente', () async {
    final c = await conteneur();
    final n = c.read(notificationsProvider);
    final m = c.read(mesureProvider);
    for (var i = 0; i < 40; i++) {
      m.suivre('cuisine_terminee', {'slug': 'r$i'});
    }
    final cuisinees = n.profil()['cuisinees'] as List;
    expect(cuisinees.length, 30);
    expect(cuisinees.last, 'r39', reason: 'on garde les plus récentes');
  });
  test('sans transport Firebase, la question ne se pose jamais et le réglage est muet', () async {
    final c = await conteneur({'mf_sessions': 5});
    Notifications.disponible = false;
    final n = c.read(notificationsProvider);
    expect(n.aDemander, isFalse);
    expect(await n.repondre(true), isFalse);
    expect(n.choix, isFalse);
    Notifications.disponible = true;
  });
}
