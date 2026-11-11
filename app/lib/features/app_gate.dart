import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth.dart';
import 'auth/welcome_screen.dart';
import 'recipes/recipes_list_screen.dart';

/// Porte d'entrée : compte connecté OU invité → l'app ; sinon → écran d'accueil.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final guest = ref.watch(guestProvider);
    if (user != null || guest) return const RecipesListScreen();
    return const WelcomeScreen();
  }
}
