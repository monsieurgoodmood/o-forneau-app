import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/acces.dart';
import '../../data/auth.dart';
import '../createurs/createurs_screen.dart';
import '../acces/claim_order_screen.dart';
import '../acces/paywall_screen.dart';
import 'auth_screen.dart';
import '../../l10n/app_localizations.dart';

/// Bloc « votre accès » : état courant et action adaptée.
class _CarteAcces extends ConsumerWidget {
  const _CarteAcces();

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final a = ref.watch(accesProvider).asData?.value ?? Acces.aucun;

    final (titre, detail, cta) = switch (a) {
      _ when a.actif && a.estClient => (
          L.of(context).accesClientActif,
          'Ouvert jusqu’au ${_date(a.expiresAt!)}. Chaque nouvelle commande le repousse, jusqu’à 12 mois.',
          null),
      _ when a.actif && a.estAbonne => (
          L.of(context).abonnementActif,
          L.of(context).resiliableAToutMomentDepuisVotre,
          null),
      _ when a.actif && a.estEssai => (
          L.of(context).essaiEnCours,
          'Il vous reste ${a.joursRestants} jour${a.joursRestants > 1 ? 's' : ''}. Vous avez commandé chez Forneau ? Activez votre accès offert.',
          L.of(context).activerMonAccesOffert),
      _ => (
          L.of(context).accesLimite,
          L.of(context).vousPouvezParcourirToutesLesRecettes,
          L.of(context).voirLesOptions),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: a.actif ? AppColors.greenSoft : AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: a.actif ? AppColors.green.withValues(alpha: 0.3) : AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(L.of(context).votreAcces, style: AppTypography.eyebrow(AppColors.gold)),
        const SizedBox(height: 4),
        Text(titre, style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
        const SizedBox(height: 4),
        Text(detail, style: t.textTheme.bodyMedium),
        // D'ou vient cet acces. Sans cette ligne, on lit une echeance sans savoir quelle
        // commande l'a ouverte, et on ne peut pas comprendre qu'un achat recent n'a rien
        // change parce qu'il n'a pas ete reclame (ticket A18).
        Consumer(builder: (context, ref2, _) {
          final cmds = ref2.watch(mesCommandesProvider).asData?.value ?? const <CommandeReclamee>[];
          if (cmds.isEmpty) return const SizedBox.shrink();
          final derniere = cmds.first;
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s8),
            child: Text(
              cmds.length == 1
                  ? 'Ouvert par votre commande ${derniere.numero} (${derniere.moisOfferts} mois).'
                  : 'Ouvert par votre commande ${derniere.numero} (${derniere.moisOfferts} mois), '
                      'sur ${cmds.length} commandes activées.',
              style: t.textTheme.labelSmall,
            ),
          );
        }),
        if (cta != null) ...[
          const SizedBox(height: AppSpacing.s16),
          FilledButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => cta.startsWith('Activer') ? const ClaimOrderScreen() : const PaywallScreen())),
            child: Text(cta),
          ),
        ],
      ]),
    );
  }
}

/// Mon compte — profil, déconnexion, suppression (page légale exigée par Play/Apple), confidentialité.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);
    final prenom = user?.userMetadata?['prenom']?.toString();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        title: Text(L.of(context).monCompte, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
        children: [
          if (user == null) ...[
            Text(L.of(context).vousNaviguezEnInvite, style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: AppSpacing.s8),
            Text(L.of(context).creezUnComptePourRetrouverVos, style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.s24),
            FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AuthScreen(mode: AuthMode.signup))), child: Text(L.of(context).creerMonCompte)),
            const SizedBox(height: AppSpacing.s8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.login))),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green), minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
              child: Text(L.of(context).jAiDejaUnCompte),
            ),
          ] else ...[
            Text(L.of(context).votreProfil, style: AppTypography.eyebrow(AppColors.gold)),
            const SizedBox(height: AppSpacing.s8),
            Text(prenom != null && prenom.isNotEmpty ? 'Bonjour $prenom' : 'Bonjour', style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: 4),
            Text(user.email ?? '', style: t.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.s24),
            const _CarteAcces(),
            const SizedBox(height: AppSpacing.s16),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(AppRadius.r16)),
              child: Text(L.of(context).vosFavorisVotreFrigoVotreListe, style: t.textTheme.bodyLarge),
            ),
            const SizedBox(height: AppSpacing.s16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateursScreen())),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green), minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(L.of(context).mesCreateursPreferes),
            ),
            const SizedBox(height: AppSpacing.s24),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authActionsProvider).signOut();
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green), minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
              icon: const Icon(Icons.logout),
              label: Text(L.of(context).meDeconnecter),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('https://app.forneau.com/legal/suppression.html'), mode: LaunchMode.externalApplication),
              child: Text(L.of(context).supprimerMonCompteEtMesDonnees, style: t.textTheme.labelLarge?.copyWith(color: AppColors.danger)),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          const Divider(color: AppColors.line),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://app.forneau.com/legal/privacy.html'), mode: LaunchMode.externalApplication),
            child: Text(L.of(context).politiqueDeConfidentialite, style: t.textTheme.labelLarge?.copyWith(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://forneau.com'), mode: LaunchMode.externalApplication),
            child: Text('forneau.com', style: t.textTheme.labelLarge?.copyWith(color: AppColors.muted)),
          ),
        ],
      ),
    );
  }
}
