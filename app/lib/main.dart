import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/auth.dart';
import 'data/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Repli propre au lieu d'un écran blanc en cas d'erreur de rendu.
  ErrorWidget.builder = (d) => const Material(
        color: Color(0xFFF3F1EB),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Un souci est survenu. Fermez et rouvrez l’app.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF243F20))),
          ),
        ),
      );

  // L'initialisation de Supabase touche le réseau : sans borne de temps, un serveur
  // injoignable retient la première image et l'utilisateur n'a qu'un écran blanc, sans
  // rien à lire. On la borne et on démarre en mode dégradé plutôt que pas du tout —
  // l'app redemandera une session dès qu'elle en aura besoin.
  try {
    await initSupabase().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Supabase init échoué (mode dégradé) : $e');
  }
  // Les réglages locaux, eux, ne sortent pas de l'appareil : une lenteur est possible,
  // une panne définitive non. On réessaie une fois avant de laisser l'erreur remonter.
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Réglages locaux lents, seconde tentative : $e');
    prefs = await SharedPreferences.getInstance();
  }
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const OForneauApp(),
    ),
  );
}

class OForneauApp extends ConsumerWidget {
  const OForneauApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Ô Forneau !',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light, // charte Forneau : clair uniquement
      routerConfig: router,
    );
  }
}
