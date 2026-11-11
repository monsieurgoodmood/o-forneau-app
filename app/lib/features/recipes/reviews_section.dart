import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/auth.dart';
import '../../data/community.dart';
import '../auth/auth_screen.dart';

const _crits = [('taste', 'Goût'), ('ease', 'Faisabilité'), ('visual', 'Visuel')];

/// Section « Avis » d'une fiche : moyenne, notes multi-critères, commentaire + photo, galerie, modération.
class ReviewsSection extends ConsumerWidget {
  final String slug;
  const ReviewsSection({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final stats = ref.watch(statsOfProvider(slug));
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Avis', style: t.textTheme.headlineMedium?.copyWith(color: AppColors.greenDeep)),
            const Spacer(),
            if (stats.count > 0) ...[
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 22),
              const SizedBox(width: 4),
              Text(stats.avg.toStringAsFixed(1).replaceAll('.', ','), style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep)),
              const SizedBox(width: 6),
              Text('(${stats.count} avis)', style: t.textTheme.labelSmall),
            ] else
              Text('Soyez le premier à noter', style: t.textTheme.labelSmall),
          ],
        ),
        if (stats.count > 0) ...[
          const SizedBox(height: AppSpacing.s8),
          Wrap(spacing: AppSpacing.s16, runSpacing: 4, children: [
            _CritAvg('Goût', stats.avgTaste),
            _CritAvg('Faisabilité', stats.avgEase),
            _CritAvg('Visuel', stats.avgVisual),
          ]),
        ],
        const SizedBox(height: AppSpacing.s16),
        if (user == null) _SignInPrompt(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen(mode: AuthMode.signup))))
        else _ReviewForm(slug: slug),
        const SizedBox(height: AppSpacing.s24),
        _PhotoGallery(slug: slug),
        const SizedBox(height: AppSpacing.s24),
        _CommentList(slug: slug),
      ],
    );
  }
}

class _CritAvg extends StatelessWidget {
  final String label;
  final double v;
  const _CritAvg(this.label, this.v);
  @override
  Widget build(BuildContext context) {
    if (v <= 0) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(width: 4),
      const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
      Text(v.toStringAsFixed(1).replaceAll('.', ','), style: Theme.of(context).textTheme.labelMedium),
    ]);
  }
}

class _SignInPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _SignInPrompt({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(AppRadius.r16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Notez cette recette, laissez un commentaire et partagez la photo de votre plat.', style: t.textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.s16),
        FilledButton(onPressed: onTap, child: const Text('Créer mon compte ou me connecter')),
      ]),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  final String slug;
  const _ReviewForm({required this.slug});
  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final Map<String, int> _vals = {};
  final _body = TextEditingController();
  dynamic _photo; // XFile
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final actions = ref.read(communityActionsProvider);
    setState(() => _busy = true);
    try {
      await actions.submitRating(widget.slug, taste: _vals['taste'], ease: _vals['ease'], visual: _vals['visual']);
      if (_body.text.trim().isNotEmpty) await actions.addComment(widget.slug, _body.text);
      if (_photo != null) await actions.uploadPhoto(widget.slug, _photo);
      if (mounted) {
        _body.clear();
        setState(() => _photo = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci, votre avis est publié.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publication impossible. Réessayez.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(bool camera) async {
    final f = await ref.read(communityActionsProvider).pickPhoto(camera: camera);
    if (f != null && mounted) setState(() => _photo = f);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final mine = ref.watch(myRatingProvider(widget.slug)).asData?.value;
    if (!_seeded && mine != null) {
      _seeded = true;
      if (mine.taste != null) _vals['taste'] = mine.taste!;
      if (mine.ease != null) _vals['ease'] = mine.ease!;
      if (mine.visual != null) _vals['visual'] = mine.visual!;
    }
    final canSubmit = !_busy && (_vals.isNotEmpty || _body.text.trim().isNotEmpty || _photo != null);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(AppRadius.r16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VOTRE AVIS', style: AppTypography.eyebrow(AppColors.gold)),
        const SizedBox(height: AppSpacing.s8),
        for (final c in _crits)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(width: 96, child: Text(c.$2, style: t.textTheme.labelLarge)),
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _vals[c.$1] = i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(i <= (_vals[c.$1] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.gold, size: 30),
                  ),
                ),
            ]),
          ),
        const SizedBox(height: AppSpacing.s8),
        TextField(
          controller: _body,
          maxLines: 3,
          maxLength: 1000,
          onChanged: (_) => setState(() {}),
          style: t.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Un commentaire ? (facultatif)',
            counterText: '',
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.r16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Row(children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(true),
            style: _pillStyle, icon: const Icon(Icons.photo_camera_outlined, size: 18), label: const Text('Photo'),
          ),
          const SizedBox(width: AppSpacing.s8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(false),
            style: _pillStyle, icon: const Icon(Icons.photo_library_outlined, size: 18), label: const Text('Galerie'),
          ),
          if (_photo != null) ...[
            const SizedBox(width: AppSpacing.s8),
            const Icon(Icons.check_circle, color: AppColors.green, size: 20),
            Text(' prête', style: t.textTheme.labelMedium),
          ],
        ]),
        const SizedBox(height: AppSpacing.s16),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          child: _busy
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Publier mon avis'),
        ),
      ]),
    );
  }

  ButtonStyle get _pillStyle => OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      );
}

class _PhotoGallery extends ConsumerWidget {
  final String slug;
  const _PhotoGallery({required this.slug});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final photos = ref.watch(photosProvider(slug)).asData?.value ?? const <RecipePhoto>[];
    if (photos.isEmpty) return const SizedBox.shrink();
    final me = ref.watch(currentUserProvider)?.id;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('LES PLATS DE LA COMMUNAUTÉ', style: AppTypography.eyebrow(AppColors.gold)),
      const SizedBox(height: AppSpacing.s8),
      SizedBox(
        height: 120,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s8),
          itemBuilder: (context, i) {
            final p = photos[i];
            return GestureDetector(
              onTap: () => _openPhoto(context, ref, p, p.userId == me),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.r8 + 4),
                child: CachedNetworkImage(imageUrl: p.url, width: 120, height: 120, fit: BoxFit.cover,
                    placeholder: (c, _) => Container(color: AppColors.greenSoft),
                    errorWidget: (c, _, __) => Container(color: AppColors.greenSoft)),
              ),
            );
          },
        ),
      ),
      if (photos.first.author != null) ...[
        const SizedBox(height: 4),
        Text('Touchez une photo pour l’agrandir.', style: t.textTheme.labelSmall),
      ],
    ]);
  }

  void _openPhoto(BuildContext context, WidgetRef ref, RecipePhoto p, bool mine) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(children: [
          Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: p.url, fit: BoxFit.contain))),
          Positioned(
            top: 12, right: 12,
            child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
          ),
          Positioned(
            bottom: 24, left: 16, right: 16,
            child: Row(children: [
              if (p.author != null) Expanded(child: Text('Par ${p.author}', style: const TextStyle(color: Colors.white))),
              if (mine)
                TextButton(
                  onPressed: () async { await ref.read(communityActionsProvider).deletePhoto(p.slug, p); if (context.mounted) Navigator.pop(context); },
                  child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                )
              else
                TextButton(
                  onPressed: () async { await ref.read(communityActionsProvider).reportPhoto(p.slug, p.id); if (context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo signalée. Merci.'))); } },
                  child: const Text('Signaler', style: TextStyle(color: Colors.white70)),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _CommentList extends ConsumerWidget {
  final String slug;
  const _CommentList({required this.slug});

  static String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);
    final comments = ref.watch(commentsProvider(slug)).asData?.value ?? const <RecipeComment>[];
    final me = ref.watch(currentUserProvider)?.id;
    if (comments.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('COMMENTAIRES', style: AppTypography.eyebrow(AppColors.gold)),
      const SizedBox(height: AppSpacing.s8),
      for (final c in comments)
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s8),
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(AppRadius.r16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(c.author ?? 'Un gourmand', style: t.textTheme.labelLarge?.copyWith(color: AppColors.greenDeep))),
              Text(_date(c.createdAt), style: t.textTheme.labelSmall),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 18,
                onSelected: (v) async {
                  final a = ref.read(communityActionsProvider);
                  if (v == 'del') await a.deleteComment(slug, c.id);
                  if (v == 'rep') { await a.reportComment(slug, c.id); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commentaire signalé. Merci.'))); }
                },
                itemBuilder: (_) => [
                  if (c.userId == me) const PopupMenuItem(value: 'del', child: Text('Supprimer'))
                  else const PopupMenuItem(value: 'rep', child: Text('Signaler')),
                ],
              ),
            ]),
            const SizedBox(height: 4),
            Text(c.body, style: t.textTheme.bodyLarge),
          ]),
        ),
    ]);
  }
}
