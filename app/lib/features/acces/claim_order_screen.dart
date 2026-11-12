import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/acces.dart';
import '../../data/auth.dart';
import '../auth/auth_screen.dart';

/// « J'ai commandé chez Forneau » — débloque 12 mois contre un numéro de commande + l'e-mail d'achat.
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
    // Pré-remplir avec l'e-mail du compte : c'est souvent le même que celui de la commande.
    _email.text = ref.read(currentUserProvider)?.email ?? '';
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
    final user = ref.watch(currentUserProvider);
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.creamTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        title: Text('Mon accès offert', style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
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
                Text(_succes!.dejaReclamee ? 'Déjà activé' : '${_moisTexte(_succes!.mois)} offerts',
                    style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
                const SizedBox(height: AppSpacing.s8),
                Text('Votre accès complet est ouvert jusqu’au ${_date(_echeance!)}.',
                    textAlign: TextAlign.center, style: t.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  _succes!.prochainSeuil != null
                      ? 'À partir de ${_succes!.prochainSeuil} € de commande, '
                        'c’est ${_moisTexte(_succes!.prochainMois!)} offerts.'
                      : 'Chaque nouvelle commande repousse votre accès.',
                  textAlign: TextAlign.center, style: t.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.s24),
                FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Commencer à cuisiner')),
              ]),
            ),
          ] else if (user == null) ...[
            Text('Créez votre compte', style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: AppSpacing.s8),
            Text('Vos 12 mois sont rattachés à un compte, pour vous suivre sur tous vos appareils.',
                style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.s24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.signup))),
              child: const Text('Créer mon compte'),
            ),
          ] else ...[
            Text('JUSQU’À 12 MOIS OFFERTS', style: AppTypography.eyebrow(AppColors.gold)),
            const SizedBox(height: AppSpacing.s8),
            Text('Vous avez commandé\nchez Forneau ?', style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
            const SizedBox(height: AppSpacing.s16),
            Text('Saisissez votre numéro de commande et l’e-mail utilisé lors de l’achat. '
                'Les deux figurent sur votre e-mail de confirmation.',
                style: t.textTheme.bodyLarge?.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.s16),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(color: AppColors.greenSoft, borderRadius: BorderRadius.circular(AppRadius.r16)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CE QUE VOUS OBTENEZ', style: AppTypography.eyebrow(AppColors.gold)),
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
                Text('Toute commande donne au moins 1 mois.', style: t.textTheme.labelSmall),
              ]),
            ),
            const SizedBox(height: AppSpacing.s24),
            _champ(_numero, 'Numéro de commande', 'ex. 2169', TextInputType.text),
            _champ(_email, 'E-mail de la commande', 'vous@exemple.com', TextInputType.emailAddress),
            if (_erreur != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.white, borderRadius: BorderRadius.circular(AppRadius.r8),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                ),
                child: Text(_erreur!, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
              ),
            ],
            const SizedBox(height: AppSpacing.s24),
            FilledButton(
              onPressed: _busy || _numero.text.trim().isEmpty ? null : _valider,
              child: _busy
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Activer mon accès offert'),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('Une commande n’active qu’un seul compte. Si vous avez plusieurs commandes, '
                'chacune repousse votre accès.',
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
