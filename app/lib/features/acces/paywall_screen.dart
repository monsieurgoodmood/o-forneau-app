import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/acces.dart';
import '../../data/auth.dart';
import '../auth/auth_screen.dart';
import '../auth/exiger_compte.dart';
import 'claim_order_screen.dart';

/// Mode vitrine : rend l'écran comme pour un utilisateur connecté, afin de produire les
/// captures exigées par la revue des stores. Sans `--dart-define=VITRINE=true` la constante
/// vaut false et le code est élagué des binaires publiés.
const _vitrine = bool.fromEnvironment('VITRINE');

/// Écran d'abonnement. Trois voies, dans cet ordre d'intérêt pour le client :
/// 1. il a commandé chez Forneau → 12 mois offerts ;
/// 2. il n'a jamais essayé → 1 mois offert, sans carte ;
/// 3. sinon → abonnement mensuel ou annuel (achat intégré Apple / Google).
/// Aucun dark pattern : la consultation des recettes reste libre, on peut toujours fermer.
class PaywallScreen extends ConsumerStatefulWidget {
  final String fonction; // nom de la fonction demandée, pour contextualiser
  const PaywallScreen({super.key, this.fonction = ''});
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<rc.Package> _forfaits = const [];
  bool _chargement = true;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final f = await ref.read(accesActionsProvider).forfaits();
    if (mounted) setState(() { _forfaits = f; _chargement = false; });
  }

  Future<void> _essai() async {
    setState(() { _busy = true; _message = null; });
    final err = await ref.read(accesActionsProvider).lancerEssai();
    if (!mounted) return;
    setState(() { _busy = false; _message = err; });
    if (err == null && mounted) Navigator.pop(context, true);
  }

  Future<void> _acheter(rc.Package p) async {
    setState(() { _busy = true; _message = null; });
    final err = await ref.read(accesActionsProvider).acheter(p);
    if (!mounted) return;
    final actif = ref.read(estPremiumProvider);
    setState(() { _busy = false; _message = err; });
    if (actif && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final connecte = _vitrine || ref.watch(currentUserProvider) != null;
    final acces = ref.watch(accesProvider).asData?.value ?? Acces.aucun;
    final essaiDejaPris = acces.estEssai; // un essai déjà posé (même expiré) reste visible
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, 0, margin, AppSpacing.s32),
        children: [
          Text('Ô FORNEAU PREMIUM', style: AppTypography.eyebrow(AppColors.gold)),
          const SizedBox(height: AppSpacing.s8),
          Text(
            widget.fonction.isEmpty
                ? 'Cuisinez accompagné'
                : '${widget.fonction} fait partie\ndes fonctions premium',
            style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep),
          ),
          const SizedBox(height: AppSpacing.s16),
          _avantages(t),
          const SizedBox(height: AppSpacing.s24),

          // 1) Voie client : la plus avantageuse, donc la première
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.greenSoft, borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VOUS AVEZ COMMANDÉ CHEZ FORNEAU ?', style: AppTypography.eyebrow(AppColors.gold)),
              const SizedBox(height: 4),
              Text('Jusqu’à 12 mois offerts', style: t.textTheme.headlineMedium?.copyWith(color: AppColors.greenDeep)),
              const SizedBox(height: 4),
              Text('Selon le montant de votre commande : 1 mois pour toute commande, 3 mois dès 70 €, '
                  '6 mois dès 100 €, 12 mois dès 150 €. Renouvelés à chaque commande.',
                  style: t.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.s16),
              FilledButton(
                onPressed: _busy ? null : () async {
                  final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const ClaimOrderScreen()));
                  if (!mounted) return;
                  if (ref.read(estPremiumProvider)) Navigator.pop(context, true);
                  else if (ok == true) setState(() {});
                },
                child: const Text('J’ai commandé chez Forneau'),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.s24),

          // 2) Essai gratuit
          if (connecte && !essaiDejaPris) ...[
            OutlinedButton(
              onPressed: _busy ? null : _essai,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green, side: const BorderSide(color: AppColors.green),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                textStyle: t.textTheme.titleMedium,
              ),
              child: const Text('Essayer 1 mois gratuitement'),
            ),
            const SizedBox(height: 6),
            Text('Sans carte bancaire. Rien ne se déclenche à la fin.',
                textAlign: TextAlign.center, style: t.textTheme.labelSmall),
            const SizedBox(height: AppSpacing.s24),
          ],

          // 3) Abonnement
          Text('S’ABONNER', style: AppTypography.eyebrow(AppColors.gold)),
          const SizedBox(height: AppSpacing.s8),
          if (!connecte)
            _carteInfo(t, 'Créez un compte pour vous abonner et retrouver votre accès sur tous vos appareils.',
                'Créer mon compte',
                () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.signup))))
          else if (_chargement)
            const Padding(padding: EdgeInsets.all(AppSpacing.s16),
                child: Center(child: CircularProgressIndicator(color: AppColors.green)))
          else if (_forfaits.isEmpty)
            _carteInfo(t, 'L’abonnement n’est pas encore disponible sur cet appareil. '
                'Vous pouvez activer vos 12 mois offerts si vous avez commandé chez Forneau.', null, null)
          else
            ...[
              for (final p in _forfaits) _forfait(t, p),
              const SizedBox(height: AppSpacing.s8),
              TextButton(
                onPressed: _busy ? null : () async {
                  setState(() => _busy = true);
                  final err = await ref.read(accesActionsProvider).restaurer();
                  if (!mounted) return;
                  setState(() { _busy = false; _message = err; });
                  if (ref.read(estPremiumProvider) && mounted) Navigator.pop(context, true);
                },
                child: Text('Restaurer un achat', style: t.textTheme.labelLarge?.copyWith(color: AppColors.muted)),
              ),
            ],

          if (_message != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(_message!, textAlign: TextAlign.center,
                style: t.textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.s16),
          Text('Sans engagement, résiliable à tout moment depuis votre compte Apple ou Google. '
              'La consultation des recettes reste toujours accessible.',
              textAlign: TextAlign.center, style: t.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _avantages(ThemeData t) {
    const items = [
      (Icons.mic, 'Mode cuisine vocal', 'Passez les étapes à la voix, les mains sales.'),
      (Icons.insights, 'Programme nutritionnel', 'Vos besoins et un menu du jour pour tout le foyer.'),
      (Icons.kitchen, 'Cuisiner avec mon frigo', 'Les recettes faisables avec ce que vous avez.'),
      (Icons.shopping_basket, 'Liste de courses', 'Les ingrédients manquants, rassemblés.'),
    ];
    return Column(children: [
      for (final (ic, titre, desc) in items)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle),
              child: Icon(ic, size: 19, color: AppColors.green),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(titre, style: t.textTheme.titleMedium?.copyWith(color: AppColors.greenDeep)),
              Text(desc, style: t.textTheme.bodyMedium),
            ])),
          ]),
        ),
    ]);
  }

  Widget _forfait(ThemeData t, rc.Package p) {
    final annuel = p.packageType == rc.PackageType.annual ||
        p.identifier.toLowerCase().contains('annual') || p.identifier.toLowerCase().contains('year');
    final prix = p.storeProduct.priceString;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Material(
        color: annuel ? AppColors.green : AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          onTap: _busy ? null : () => _acheter(p),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: annuel ? AppColors.green : AppColors.line),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(annuel ? 'Annuel' : 'Mensuel',
                    style: t.textTheme.titleMedium?.copyWith(
                        color: annuel ? Colors.white : AppColors.greenDeep)),
                Text(annuel ? 'Le plus avantageux' : 'Sans engagement',
                    style: t.textTheme.bodyMedium?.copyWith(
                        color: annuel ? Colors.white70 : AppColors.muted)),
              ])),
              Text(prix, style: t.textTheme.titleLarge?.copyWith(
                  color: annuel ? Colors.white : AppColors.greenDeep)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _carteInfo(ThemeData t, String texte, String? cta, VoidCallback? onTap) => Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(AppRadius.r16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(texte, style: t.textTheme.bodyLarge),
          if (cta != null) ...[
            const SizedBox(height: AppSpacing.s16),
            FilledButton(onPressed: onTap, child: Text(cta)),
          ],
        ]),
      );
}

/// Porte d'accès aux fonctions premium, en deux temps.
///
/// 1. Pas de compte → invitation à en créer un. L'accès est rattaché à un compte :
///    un invité ne peut rien activer, donc inutile de lui parler d'abonnement d'abord.
/// 2. Compte sans accès → écran d'abonnement.
///
/// Renvoie true si la fonction peut s'ouvrir.
Future<bool> exigerPremium(BuildContext context, WidgetRef ref, {String fonction = ''}) async {
  if (!await exigerCompte(context, ref, fonction: fonction)) return false;
  if (ref.read(estPremiumProvider)) return true;
  await ref.read(accesProvider.future); // s'assurer d'avoir la dernière vérité serveur
  if (ref.read(estPremiumProvider)) return true;
  if (!context.mounted) return false;
  final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => PaywallScreen(fonction: fonction)));
  return ok == true || ref.read(estPremiumProvider);
}
