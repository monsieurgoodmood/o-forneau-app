import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/acces.dart';
import '../data/auth.dart';
import 'auth/welcome_screen.dart';
import 'recipes/recipes_list_screen.dart';

/// Porte d'entrée : compte connecté OU invité → l'app ; sinon → écran d'accueil.
/// Aligne aussi l'identité RevenueCat sur le compte : l'appUserID est l'UUID Supabase,
/// c'est lui qui permet au webhook de retrouver l'utilisateur après un achat.
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});
  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  String? _dernierUser;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final guest = ref.watch(guestProvider);

    if (user?.id != _dernierUser) {
      _dernierUser = user?.id;
      if (user != null) {
        RevenueCat.configurer(user.id);
      } else {
        RevenueCat.deconnecter();
      }
    }

    if (user != null || guest) return const RecipesListScreen();
    return const WelcomeScreen();
  }
}
