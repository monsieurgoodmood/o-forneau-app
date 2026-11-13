import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/acces.dart';
import '../../data/auth.dart';
import '../auth/auth_screen.dart';
import '../../l10n/app_localizations.dart';

/// Mode vitrine : rend l'écran comme pour un utilisateur connecté, afin de produire les
/// captures exigées par la revue des stores. Sans `--dart-define=VITRINE=true` la constante
/// vaut false et le code est élagué des binaires publiés.
const _vitrine = bool.fromEnvironment('VITRINE');

/// « J'ai commandé chez Forneau » — débloque de 1 à 12 mois selon le montant de la commande,
/// contre un numéro de commande et lL.of(context).eMailDachat.
class ClaimOrderScreen extends ConsumerStatefulWidget {
  const ClaimOrderScreen({super.key});
  @override
  ConsumerState<ClaimOrderScreen> createState() => _ClaimOrderScreenState();
}

class _ClaimOrderScreenState extends ConsumerState<ClaimOrderScreen> {
  final _numero = TextEditingController();
  final _email = TextEditingController();
  bool _busy = false;
  String? _erreur;
  ResultatCommande? _succes;
  DateTime? _echeance;

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec lL.of(context).eMailDuCompteCest souvent le même que celui de la commande.
    _email.text = _vitrine ? '' : (ref.read(currentUserProvider)?.email ?? '');
  }

  @override
  void dispose() {
    _numero.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    setState(() { _busy = true; _erreur = null; });
    final res = await ref.read(accesActionsProvider).reclamerCommande(
          numero: _numero.text.trim(), email: _email.text.trim(),
        );
    if (!mounted) return;
    if (res.ok) {
      final a = ref.read(accesProvider).asData?.value;
      setState(() {
        _busy = false;
        _succes = res;
        _echeance = a?.expiresAt ?? DateTime.now().add(Duration(days: 30 * (res.mois == 0 ? 1 : res.mois)));
      });
    } else {
      setState(() { _busy = false; _erreur = res.erreur; });
    }
  }

  static String _moisTexte(int m) => m == 12 ? '12 mois' : '$m mois';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final connecte = _vitrine || ref.watch(currentUserProvider) != null;
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        title: Text(L.of(context).monAccesOffert, style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, AppSpacing.s24, margin, AppSpacing.s32),
        children: [
          if (_succes != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.s24),
              decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(AppRadius.r16)),
              child: Column(children: [
                const Icon(Icons.check_circle, color: AppColors.green, size: 44),
                const SizedBox(height: AppSpacing.s16),
                Text(_succes!.dejaReclamee ? L.of(context).dejaActive : '${_moisTexte(_succes!.mois)} offerts',
                    style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
                const SizedBox(height: AppSpacing.s8),
                Text('Votre accès complet est ouvert jusqu’au ${_date(_echeance!)}.',
                    textAlign: TextAlign.center, style: t.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  _succes!.prochainSeuil != null
                      ? 'À partir de ${_succes!.prochainSeuil} € de commande, c’est ${_moisTexte(_succes!.prochainMois!)} offerts.'
                      : L.of(context).chaqueNouvelleCommandeRepousseVotreAcces,
                  textAlign: TextAlign.center, style: t.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.s24),
                FilledButton(onPressed: () => Navigator.pop(context), child: Text(L.of(context).commencerACuisiner)),
              ]),
            ),
          ] else if (!connecte) ...[
            Text(L.of(context).creezVotreCompte, style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: AppSpacing.s8),
            Text(L.of(context).vosMoisOffertsSontRattachesA,
                style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.s24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.signup))),
              child: Text(L.of(context).creerMonCompte),
            ),
          ] else ...[
            Text(L.of(context).jusquA12MoisOfferts, style: AppTypography.eyebrow(AppColors.gold)),
            const SizedBox(height: AppSpacing.s8),
            Text('Vous avez commandé\nchez Forneau ?', style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: AppSpacing.s16),
            Text(L.of(context).saisissezVotreNumeroDeCommandeEt,
                style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.s16),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(AppRadius.r16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(L.of(context).ceQueVousObtenez, style: AppTypography.eyebrow(AppColors.gold)),
                const SizedBox(height: AppSpacing.s8),
                for (final (seuil, mois) in kPaliers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      SizedBox(width: 86, child: Text('dès $seuil €', style: t.textTheme.bodyMedium)),
                      Text('${_moisTexte(mois)} offerts',
                          style: t.textTheme.labelLarge?.copyWith(color: AppColors.greenDeep)),
                    ]),
                  ),
                Text(L.of(context).touteCommandeDonneAuMoins1, style: t.textTheme.labelSmall),
              ]),
            ),
            const SizedBox(height: AppSpacing.s24),
            _champ(_numero, L.of(context).numeroDeCommande, 'ex. 2169', TextInputType.text),
            _champ(_email, L.of(context).eMailDeLaCommande, 'vous@exemple.com', TextInputType.emailAddress),
            if (_erreur != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.r8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_erreur!, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
                  const SizedBox(height: AppSpacing.s8),
                  // Le message serveur est volontairement identique que la commande
                  // n'existe pas ou que l'e-mail diffère — sinon on permettrait de
                  // deviner les numéros valides. Mais l'utilisateur de bonne foi reste
                  // alors sans piste : on lui donne les trois causes réelles (A18).
                  Text(
                    'Trois choses à vérifier :\n'
                    '• le numéro tel qu’il figure sur l’e-mail de confirmation, avec le #\n'
                    '• l’adresse e-mail utilisée lors de l’achat, qui n’est pas forcément '
                    'celle de ce compte\n'
                    '• que la commande est bien payée, et qu’elle n’a pas déjà servi à '
                    'ouvrir un autre compte',
                    style: t.textTheme.labelSmall,
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Toujours bloqué ? Écrivez-nous à info@forneau.fr en indiquant votre '
                    'numéro de commande : nous activons l’accès à la main.',
                    style: t.textTheme.labelSmall?.copyWith(color: AppColors.muted),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            FilledButton(
              onPressed: _busy || _numero.text.trim().isEmpty ? null : _valider,
              child: _busy
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(L.of(context).activerMonAccesOffert),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(L.of(context).uneCommandeNActiveQuUn,
                style: t.textTheme.labelSmall),
          ],
        ],
      ),
    );
  }

  Widget _champ(TextEditingController c, String label, String hint, TextInputType kind) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s16),
        child: TextField(
          controller: c,
          keyboardType: kind,
          onChanged: (_) => setState(() {}),
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            labelText: label, hintText: hint,
            filled: true, fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.r16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r16),
                borderSide: const BorderSide(color: AppColors.green)),
          ),
        ),
      );

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
