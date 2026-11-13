import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Composants partagés Programme / Foyer — réplique du web (pastilles segmentées, cartes de choix, champs).

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
        child: Text(text.toUpperCase(), style: AppTypography.eyebrow(AppColors.gold)),
      );
}

class SectionCard extends StatelessWidget {
  final Widget child;
  const SectionCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: child,
      );
}

/// Choix binaire côte à côte (Femme/Homme, Juste pour moi/Pour plusieurs…).
class SegPair extends StatelessWidget {
  final String a, b;
  final String? subA, subB;
  final bool first;
  final ValueChanged<bool> onChanged;
  const SegPair({super.key, required this.a, required this.b, this.subA, this.subB, required this.first, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String? sub, bool on, VoidCallback tap) => Expanded(
          child: Material(
            color: on ? AppColors.greenSoft : const Color(0xFFE8E6E1),
            borderRadius: BorderRadius.circular(AppRadius.r8 + 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.r8 + 4),
              onTap: tap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.r8 + 4),
                  border: Border.all(color: on ? AppColors.green : AppColors.line, width: on ? 1.5 : 1),
                ),
                child: Column(children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: on ? AppColors.greenDeep : AppColors.ink)),
                  if (sub != null) Text(sub, style: Theme.of(context).textTheme.bodyMedium),
                ]),
              ),
            ),
          ),
        );
    return Row(children: [
      cell(a, subA, first, () => onChanged(true)),
      const SizedBox(width: AppSpacing.s16),
      cell(b, subB, !first, () => onChanged(false)),
    ]);
  }
}

/// Carte de choix (objectif, type d'alimentation).
class ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final bool on;
  final VoidCallback onTap;
  /// null = la carte prend la largeur que son parent lui donne. Une largeur figee
  /// deborde des le premier telephone etroit : c'est ce qui coupait les choix du programme.
  final double? width;
  const ChoiceCard({super.key, required this.icon, required this.label, this.sub, required this.on, required this.onTap, this.width});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Material(
      color: on ? AppColors.greenSoft : AppColors.cardBg,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16, horizontal: AppSpacing.s8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: on ? AppColors.green : AppColors.line.withValues(alpha: 0.6), width: on ? 1.5 : 1),
          ),
          child: Column(children: [
            Icon(icon, color: AppColors.green, size: 24),
            const SizedBox(height: AppSpacing.s8),
            Text(label, textAlign: TextAlign.center, style: t.textTheme.titleMedium?.copyWith(color: AppColors.greenDeep)),
            if (sub != null) ...[const SizedBox(height: 2), Text(sub!, textAlign: TextAlign.center, style: t.textTheme.bodyMedium)],
          ]),
        ),
      ),
    );
  }
}

/// Champ numérique étiqueté (ÂGE, TAILLE, POIDS).
class NumField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? suffix;
  const NumField({super.key, required this.label, required this.value, required this.onChanged, this.suffix});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AppTypography.eyebrow(AppColors.muted).copyWith(fontSize: 11)),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value > 0 ? '$value' : '',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(int.tryParse(v.trim()) ?? 0),
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: '—',
          suffixText: suffix,
          filled: true,
          fillColor: const Color(0xFFE8E6E1),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.r8 + 4), borderSide: const BorderSide(color: AppColors.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.r8 + 4), borderSide: const BorderSide(color: AppColors.line)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.r8 + 4), borderSide: const BorderSide(color: AppColors.green)),
        ),
      ),
    ]);
  }
}

/// Liste déroulante étiquetée (activité, régime d'un membre).
class LabeledDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;
  const LabeledDropdown({super.key, required this.label, required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: AppTypography.eyebrow(AppColors.muted).copyWith(fontSize: 11)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E6E1),
          borderRadius: BorderRadius.circular(AppRadius.r8 + 4),
          border: Border.all(color: AppColors.line),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: options.containsKey(value) ? value : options.keys.first,
            isExpanded: true,
            style: Theme.of(context).textTheme.bodyLarge,
            items: [for (final e in options.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) { if (v != null) onChanged(v); },
          ),
        ),
      ),
    ]);
  }
}

/// Compteur − N + (personnes).
class CounterCard extends StatelessWidget {
  final int value;
  final String label;
  final int min, max;
  final ValueChanged<int> onChanged;
  const CounterCard({super.key, required this.value, required this.label, this.min = 1, this.max = 12, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget btn(IconData ic, VoidCallback? tap) => Material(
          color: const Color(0xFFE8E6E1),
          shape: const CircleBorder(),
          child: InkWell(customBorder: const CircleBorder(), onTap: tap, child: Padding(padding: const EdgeInsets.all(14), child: Icon(ic, color: tap == null ? AppColors.muted : AppColors.greenDeep))),
        );
    return SectionCard(
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        btn(Icons.remove, value > min ? () => onChanged(value - 1) : null),
        Column(children: [
          Text('$value', style: t.textTheme.displayLarge?.copyWith(color: AppColors.greenDeep, fontSize: 40)),
          Text(label.toUpperCase(), style: AppTypography.eyebrow(AppColors.muted)),
        ]),
        btn(Icons.add, value < max ? () => onChanged(value + 1) : null),
      ]),
    );
  }
}
