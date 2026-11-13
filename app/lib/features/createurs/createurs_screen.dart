import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/createurs.dart';

/// « Mes créateurs » — l'utilisateur indique les comptes Instagram ou TikTok dont il
/// aimerait retrouver les recettes. La proposition oriente la collecte ; on ne promet
/// donc pas une publication, on dit qu'on regarde. Les recettes publiées restent
/// réécrites et ne portent ni le nom du créateur ni ses images.
class CreateursScreen extends ConsumerStatefulWidget {
  const CreateursScreen({super.key});
  @override
  ConsumerState<CreateursScreen> createState() => _CreateursScreenState();
}

class _CreateursScreenState extends ConsumerState<CreateursScreen> {
  final _saisie = TextEditingController();
  Plateforme _plateforme = Plateforme.instagram;
  bool _busy = false;
  String? _message;
  bool _succes = false;

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  Future<void> _proposer() async {
    final texte = _saisie.text;
    final lien = analyserLien(texte, parDefaut: _plateforme);
    if (!lien.valide) {
      setState(() { _message = lien.erreur; _succes = false; });
      return;
    }
    setState(() { _busy = true; _message = null; });
    final err = await ref.read(createursActionsProvider).proposer(
          lien: lien,
          url: texte.startsWith('http') ? texte.trim() : null,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = err ?? 'C’est noté. On regarde ce compte.';
      _succes = err == null;
      if (err == null) _saisie.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final margin = AppSpacing.screenMargin(MediaQuery.sizeOf(context).width);
    final mes = ref.watch(mesCreateursProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        elevation: 0,
        title: Text('Mes créateurs',
            style: t.textTheme.headlineSmall?.copyWith(color: AppColors.greenDeep)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(margin, 0, margin, AppSpacing.s32),
        children: [
          Text('VOS COMPTES PRÉFÉRÉS', style: AppTypography.eyebrow(AppColors.gold)),
          const SizedBox(height: AppSpacing.s8),
          Text('Quels créateurs voulez-vous retrouver ?',
              style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Collez le lien de son profil Instagram ou TikTok, ou tapez simplement son pseudo. '
            'Plus un compte est demandé, plus vite on s’en occupe.',
            style: t.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.s24),

          _choixPlateforme(t),
          const SizedBox(height: AppSpacing.s16),
          TextField(
            controller: _saisie,
            autocorrect: false,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _proposer(),
            decoration: InputDecoration(
              labelText: 'Lien du profil ou pseudo',
              hintText: _plateforme == Plateforme.instagram
                  ? 'instagram.com/soncompte  ou  @soncompte'
                  : 'tiktok.com/@soncompte  ou  @soncompte',
              filled: true,
              fillColor: AppColors.cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.r16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          FilledButton(
            onPressed: _busy ? null : _proposer,
            child: Text(_busy ? 'Envoi…' : 'Proposer ce créateur'),
          ),

          if (_message != null) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(_message!,
                textAlign: TextAlign.center,
                style: t.textTheme.bodyMedium
                    ?.copyWith(color: _succes ? AppColors.green : AppColors.danger)),
          ],

          const SizedBox(height: AppSpacing.s32),
          Text('VOS PROPOSITIONS', style: AppTypography.eyebrow(AppColors.gold)),
          const SizedBox(height: AppSpacing.s8),
          mes.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: Center(child: CircularProgressIndicator(color: AppColors.green)),
            ),
            error: (_, __) => Text('Liste indisponible pour le moment.', style: t.textTheme.bodyMedium),
            data: (liste) => liste.isEmpty
                ? Text('Vous n’avez encore proposé personne.', style: t.textTheme.bodyMedium)
                : Column(children: [for (final c in liste) _ligne(t, c)]),
          ),

          const SizedBox(height: AppSpacing.s24),
          Text(
            'Les recettes sont toujours réécrites par nos soins, avec nos propres photos. '
            'Nous ne reprenons ni les textes ni les images des créateurs.',
            textAlign: TextAlign.center,
            style: t.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _choixPlateforme(ThemeData t) => Row(
        children: [
          for (final p in Plateforme.values)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: p == Plateforme.instagram ? AppSpacing.s8 : 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() => _plateforme = p),
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _plateforme == p ? AppColors.greenSoft : AppColors.cardBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: _plateforme == p ? AppColors.green : AppColors.line),
                    ),
                    child: Text(p.nom,
                        style: t.textTheme.titleMedium?.copyWith(
                            color: _plateforme == p ? AppColors.greenDeep : AppColors.muted)),
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _ligne(ThemeData t, Createur c) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s8),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('@${c.handle}',
                  style: t.textTheme.titleMedium?.copyWith(color: AppColors.greenDeep)),
              Text('${c.plateforme.nom} · ${c.etat}', style: t.textTheme.bodyMedium),
            ]),
          ),
          IconButton(
            tooltip: 'Retirer',
            icon: const Icon(Icons.close, color: AppColors.muted, size: 20),
            onPressed: () => ref.read(createursActionsProvider).retirer(c.id),
          ),
        ]),
      );
}
