import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/acces/claim_order_screen.dart';
import '../../features/acces/paywall_screen.dart';
import '../../features/app_gate.dart';
import '../../features/recipes/recipe_detail_screen.dart';

/// Mode vitrine : ouvre directement les écrans d'accès, pour produire les captures
/// exigées par la revue des stores. Sans `--dart-define=VITRINE=true` la constante vaut
/// false, les routes ne sont pas construites et le code est élagué des binaires publiés.
const _vitrine = bool.fromEnvironment('VITRINE');

/// Routeur go_router. '/' passe par le gate (accueil Compte/Invité).
/// Deep link : /recipe/<slug>.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppGate()),
      GoRoute(
        path: '/recipe/:slug',
        builder: (context, state) => RecipeDetailScreen(slug: state.pathParameters['slug']!),
      ),
      if (_vitrine) ...[
        GoRoute(path: '/vitrine/abonnement', builder: (_, __) => const PaywallScreen(fonction: 'Le mode cuisine')),
        GoRoute(path: '/vitrine/commande', builder: (_, __) => const ClaimOrderScreen()),
      ],
    ],
  );
});
