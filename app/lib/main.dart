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

  // Aucune initialisation ne doit pouvoir retenir la première image : un await qui ne
  // revient jamais donnerait un écran blanc muet, sans erreur à lire. On borne les deux,
  // et on démarre en mode dégradé plutôt que de ne pas démarrer du tout.
  const limite = Duration(seconds: 8);
  try {
    await initSupabase().timeout(limite);
  } catch (e) {
    debugPrint('Supabase init échoué (mode dégradé) : $e');
  }
  SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance().timeout(limite);
  } catch (e) {
    debugPrint('SharedPreferences indisponible, réglages en mémoire : $e');
    SharedPreferences.setMockInitialValues({});
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
