import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/app_router.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'data/auth.dart';
import 'data/mesure.dart';
import 'data/notifications.dart';
import 'features/notifications/consentement_notifications.dart';
import 'data/supabase_client.dart';
import 'features/mesure/consentement_mesure.dart';

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
  // Firebase ne sert qu'au transport des notifications (voir notifications.dart). Borné
  // lui aussi : sans lui, l'app démarre, simplement sans notifications.
  await Notifications.initialiser();
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

class OForneauApp extends ConsumerStatefulWidget {
  const OForneauApp({super.key});

  @override
  ConsumerState<OForneauApp> createState() => _OForneauAppState();
}

class _OForneauAppState extends ConsumerState<OForneauApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // La question de la mesure n'est posée qu'une fois l'app affichée, et elle attend
    // trois secondes : on laisse voir ce qu'on propose avant de demander quoi que ce soit.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final notifs = ref.read(notificationsProvider);
      await notifs.compterSession();
      notifs.brancher(ref.read(appRouterProvider));
      unawaited(notifs.rafraichirSiBesoin());
      if (!mounted) return;
      await ConsentementMesure.demanderSiBesoin(context, ref);
      // La question des notifications vient APRÈS celle de la mesure, jamais en même temps :
      // deux fenêtres d'affilée au premier écran, c'est un péage, pas un choix.
      if (mounted) await ConsentementNotifications.demanderSiBesoin(context, ref);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    // Sans cela, le temps passé sur le dernier écran ne serait jamais compté : l'app part
    // en arrière-plan et l'événement reste dans la file.
    if (etat != AppLifecycleState.resumed) ref.read(mesureProvider).miseEnPause();
    if (etat == AppLifecycleState.resumed) unawaited(ref.read(notificationsProvider).rafraichirSiBesoin());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Ô Forneau !',
      debugShowCheckedModeBanner: false,
      // Langues des clients reels, mesurees sur 713 commandes payees : francais 80,9 %,
      // anglais 10,4 %, allemand 5,8 %, italien 1,1 %, neerlandais 0,8 %, espagnol 0,6 %,
      // portugais 0,3 %. Ensemble, 99,9 % des clients.
      localizationsDelegates: L.localizationsDelegates,
      supportedLocales: L.supportedLocales,
      theme: AppTheme.light,
      themeMode: ThemeMode.light, // charte Forneau : clair uniquement
      routerConfig: router,
    );
  }
}
