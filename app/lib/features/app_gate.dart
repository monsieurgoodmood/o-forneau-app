import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/acces.dart';
import '../data/auth.dart';
import '../data/recipes_repository.dart';
import 'auth/welcome_screen.dart';
import 'recipes/recipes_list_screen.dart';

/// Porte dL.of(context).entreeCompteConnecteOuInviteLapp ; sinon → écran d'accueil.
/// Aligne aussi lL.of(context).identiteRevenuecatSurLeCompteLappUserID est l'UUID Supabase,
/// cL.of(context).estLuiQuiPermetAuWebhookutilisateur après un achat.
class AppGate extends ConsumerStatefulWidget {
  const AppGate({super.key});
  @override
  ConsumerState<AppGate> createState() => _AppGateState();
}

class _AppGateState extends ConsumerState<AppGate> {
  String? _dernierUser;

  @override
  Widget build(BuildContext context) {
    // La langue du catalogue suit celle du telephone, parmi celles qu'on embarque.
    final langue = Localizations.localeOf(context).languageCode;
    if (kLanguesCatalogue.contains(langue) &&
        ref.read(langueCatalogueProvider) != langue) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(langueCatalogueProvider.notifier).state = langue);
    }

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
