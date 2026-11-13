import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/acces/claim_order_screen.dart';
import '../../features/acces/paywall_screen.dart';
import '../../features/app_gate.dart';
import '../../features/auth/account_screen.dart';
import '../../features/createurs/createurs_screen.dart';
import '../../features/frigo/courses_screen.dart';
import '../../features/frigo/frigo_screen.dart';
import '../../features/programme/foyer_screen.dart';
import '../../features/programme/programme_screen.dart';
import '../../features/recipes/favorites_screen.dart';
import '../../features/recipes/recipe_detail_screen.dart';

/// Mode vitrine : ouvre directement les écrans d'accès, pour produire les captures
/// exigées par la revue des stores. Sans `--dart-define=VITRINE=true` la constante vaut
/// false, les routes ne sont pas construites et le code est élagué des binaires publiés.
const _vitrine = bool.fromEnvironment('VITRINE');

/// Routeur go_router. '/' passe par le gate (accueil Compte/Invité).
///
/// Chaque écran a une adresse stable et partageable (ticket A23) : les appels à l'action
/// du site menaient tous à la racine, et un lien vers le programme ou une recette ne
/// tombait nulle part. Ces chemins sont ceux du site, pour qu'un lien marche des deux
/// côtés : /recipe/<slug>, /programme, /frigo, /courses, /favoris, /foyer, /createurs,
/// /compte.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppGate()),
      GoRoute(
        path: '/recipe/:slug',
        builder: (context, state) => RecipeDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(path: '/programme', builder: (_, __) => const ProgrammeScreen()),
      GoRoute(path: '/frigo', builder: (_, __) => const FrigoScreen()),
      GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
      GoRoute(path: '/favoris', builder: (_, __) => const FavoritesScreen()),
      GoRoute(path: '/foyer', builder: (_, __) => const FoyerScreen()),
      GoRoute(path: '/createurs', builder: (_, __) => const CreateursScreen()),
      GoRoute(path: '/compte', builder: (_, __) => const AccountScreen()),
      if (_vitrine) ...[
        GoRoute(path: '/vitrine/abonnement', builder: (_, __) => const PaywallScreen(fonction: 'Le mode cuisine')),
        GoRoute(path: '/vitrine/commande', builder: (_, __) => const ClaimOrderScreen()),
      ],
    ],
  );
});
