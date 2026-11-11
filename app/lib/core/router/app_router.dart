import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/app_gate.dart';
import '../../features/recipes/recipe_detail_screen.dart';

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
    ],
  );
});
