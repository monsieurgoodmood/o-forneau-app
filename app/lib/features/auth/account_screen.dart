import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/auth.dart';
import 'auth_screen.dart';

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
        title: Text('Mon compte', style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, AppSpacing.s16, margin, AppSpacing.s32),
        children: [
          if (user == null) ...[
            Text('Vous naviguez en invité', style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: AppSpacing.s8),
            Text('Créez un compte pour retrouver vos favoris, votre frigo, votre programme et vos avis sur tous vos appareils.', style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.s24),
            FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.signup))), child: const Text('Créer mon compte')),
            const SizedBox(height: AppSpacing.s8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.login))),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green), minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
              child: const Text('J’ai déjà un compte'),
            ),
          ] else ...[
            Text('VOTRE PROFIL', style: AppTypography.eyebrow(AppColors.gold)),
            const SizedBox(height: AppSpacing.s8),
            Text(prenom != null && prenom.isNotEmpty ? 'Bonjour $prenom' : 'Bonjour', style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: 4),
            Text(user.email ?? '', style: t.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.s24),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(AppRadius.r16)),
              child: Text('Vos favoris, votre frigo, votre liste de courses, votre programme et votre foyer sont synchronisés avec ce compte (données hébergées en Europe).', style: t.textTheme.bodyLarge),
            ),
            const SizedBox(height: AppSpacing.s24),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authActionsProvider).signOut();
                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
              },
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green), minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
              icon: const Icon(Icons.logout),
              label: const Text('Me déconnecter'),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('https://app.forneau.com/legal/suppression.html'), mode: LaunchMode.externalApplication),
              child: Text('Supprimer mon compte et mes données', style: t.textTheme.labelLarge?.copyWith(color: AppColors.danger)),
            ),
          ],
          const SizedBox(height: AppSpacing.s24),
          const Divider(color: AppColors.line),
          TextButton(
            onPressed: () => launchUrl(Uri.parse('https://app.forneau.com/legal/privacy.html'), mode: LaunchMode.externalApplication),
            child: Text('Politique de confidentialité', style: t.textTheme.labelLarge?.copyWith(color: AppColors.muted)),
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
