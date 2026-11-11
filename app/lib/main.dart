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

  try {
    await initSupabase();
  } catch (e) {
    debugPrint('Supabase init échoué (mode dégradé) : $e');
  }
  final prefs = await SharedPreferences.getInstance();
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
