import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/recipe.dart';

/// Mode cuisine plein écran, mains libres : étape par étape, gros texte, minuteur par étape,
/// écran anti-veille, lecture vocale des étapes et commandes vocales fr-FR
/// (« étape suivante », « précédent », « répète », « minuteur », « pause », « terminé »).
class CookModeScreen extends StatefulWidget {
  final Recipe recipe;
  const CookModeScreen({super.key, required this.recipe});
  @override
  State<CookModeScreen> createState() => _CookModeScreenState();
}

class _CookModeScreenState extends State<CookModeScreen> {
  final _controller = PageController();
  final _stt = SpeechToText();
  final _tts = FlutterTts();
  int _index = 0;
  Timer? _timer;
  int _remaining = 0;
  bool _voice = false; // pilotage vocal actif
  bool _sttReady = false;
  bool _speaking = false;
  String _status = '';

  List<RecipeStep> get _steps => widget.recipe.steps;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _tts.setLanguage('fr-FR');
    _tts.setSpeechRate(0.48);
    _tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stt.stop();
    _tts.stop();
    WakelockPlus.disable();
    _controller.dispose();
    super.dispose();
  }

  // ---------- Voix ----------
  Future<void> _toggleVoice() async {
    if (_voice) {
      setState(() { _voice = false; _status = ''; });
      await _stt.stop();
      await _tts.stop();
      return;
    }
    if (!_sttReady) {
      _sttReady = await _stt.initialize(
        onStatus: (s) { if (_voice && !_speaking && (s == 'done' || s == 'notListening')) _listen(); },
        onError: (e) { if (_voice && !_speaking) Future.delayed(const Duration(milliseconds: 600), _listen); },
      );
    }
    if (!_sttReady) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Micro indisponible. Autorisez-le dans les réglages.')));
      return;
    }
    setState(() { _voice = true; _status = 'Je vous écoute'; });
    await _speak('Mode vocal activé. Dites : étape suivante, précédent, répète, minuteur, ou terminé.');
    await _speakStep();
  }

  Future<void> _listen() async {
    if (!_voice || !mounted || _speaking || _stt.isListening) return;
    await _stt.listen(
      onResult: (r) { if (r.finalResult) _handle(r.recognizedWords); },
      localeId: 'fr_FR',
      listenOptions: SpeechListenOptions(partialResults: false, cancelOnError: false, listenMode: ListenMode.dictation),
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 40),
    );
  }

  Future<void> _speak(String text) async {
    _speaking = true;
    try { await _stt.stop(); } catch (_) {}
    try { await _tts.speak(text); } catch (_) {}
    _speaking = false;
    if (_voice) _listen();
  }

  Future<void> _speakStep() async {
    final s = _steps[_index];
    final dur = (s.seconds != null && s.seconds! > 0) ? ' Minuteur conseillé : ${_fmtSpoken(s.seconds!)}.' : '';
    await _speak('Étape ${_index + 1} sur ${_steps.length}. ${s.text}$dur');
  }

  void _handle(String heard) {
    final h = heard.toLowerCase();
    setState(() => _status = '« $heard »');
    if (h.contains('suivant') || h.contains('après') || h.contains('continue')) { _next(); return; }
    if (h.contains('précéd') || h.contains('retour') || h.contains('arrière')) { _prev(); return; }
    if (h.contains('répèt') || h.contains('repet') || h.contains('encore')) { _speakStep(); return; }
    if (h.contains('minuteur') || h.contains('chrono') || h.contains('lance')) {
      final s = _steps[_index].seconds;
      if (s != null && s > 0) { _startTimer(s); _speak('Minuteur lancé, ${_fmtSpoken(s)}.'); } else { _speak('Pas de minuteur pour cette étape.'); }
      return;
    }
    if (h.contains('pause') || h.contains('stop') || h.contains('arrête')) { _timer?.cancel(); setState(() => _remaining = 0); _speak('Minuteur arrêté.'); return; }
    if (h.contains('terminé') || h.contains('fini') || h.contains('quitte')) { _speak('Bon appétit.').then((_) { if (mounted) Navigator.pop(context); }); return; }
    if (_voice) _listen();
  }

  // ---------- Navigation ----------
  void _next() {
    if (_index >= _steps.length - 1) { _speak('C’était la dernière étape. Bon appétit.'); return; }
    _controller.nextPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
  }

  void _prev() {
    if (_index == 0) { if (_voice) _listen(); return; }
    _controller.previousPage(duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
  }

  void _onPage(int i) {
    _timer?.cancel();
    setState(() { _index = i; _remaining = 0; });
    if (_voice) _speakStep();
  }

  // ---------- Minuteur ----------
  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _remaining = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (tm) {
      if (_remaining <= 1) {
        tm.cancel();
        setState(() => _remaining = 0);
        HapticFeedback.heavyImpact();
        _speak('Minuteur terminé.');
      } else {
        setState(() => _remaining--);
      }
    });
  }

  String _fmt(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  String _fmtSpoken(int s) {
    final m = s ~/ 60, r = s % 60;
    if (m == 0) return '$r secondes';
    return r == 0 ? '$m minutes' : '$m minutes $r';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final last = _index == _steps.length - 1;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s16, AppSpacing.s8, AppSpacing.s8, 0),
              child: Row(children: [
                Expanded(
                  child: Text(widget.recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: t.textTheme.titleLarge?.copyWith(color: AppColors.greenDeep, fontSize: 18)),
                ),
                IconButton(
                  tooltip: _voice ? 'Désactiver le vocal' : 'Activer le vocal',
                  onPressed: _toggleVoice,
                  icon: Icon(_voice ? Icons.mic : Icons.mic_none, color: _voice ? AppColors.green : AppColors.muted),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: AppColors.greenDeep)),
              ]),
            ),
            LinearProgressIndicator(value: (_index + 1) / _steps.length, backgroundColor: AppColors.greenSoft, color: AppColors.green, minHeight: 3),
            if (_voice)
              Container(
                width: double.infinity,
                color: AppColors.greenSoft,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: 8),
                child: Row(children: [
                  const Icon(Icons.graphic_eq, size: 16, color: AppColors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_status.isEmpty ? 'Je vous écoute' : _status, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.labelMedium?.copyWith(color: AppColors.greenDeep))),
                  Text('« suivante » · « répète » · « minuteur »', style: t.textTheme.labelSmall),
                ]),
              ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: _onPage,
                itemCount: _steps.length,
                itemBuilder: (context, i) {
                  final step = _steps[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('ÉTAPE ${i + 1} / ${_steps.length}', style: AppTypography.eyebrow(AppColors.gold)),
                      const SizedBox(height: AppSpacing.s24),
                      Expanded(child: SingleChildScrollView(child: Text(step.text, style: AppTypography.cookStep(AppColors.ink).copyWith(fontSize: 26, height: 1.5)))),
                      if (step.seconds != null && step.seconds! > 0)
                        Center(child: Column(children: [
                          if (_remaining > 0) Text(_fmt(_remaining), style: t.textTheme.displayLarge?.copyWith(color: AppColors.green, fontSize: 48)),
                          const SizedBox(height: AppSpacing.s8),
                          OutlinedButton.icon(
                            onPressed: () => _startTimer(step.seconds!),
                            style: _pill,
                            icon: const Icon(Icons.timer_outlined),
                            label: Text(_remaining > 0 ? 'Relancer le minuteur' : 'Lancer ${_fmt(step.seconds!)}'),
                          ),
                        ])),
                    ]),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Row(children: [
                if (_index > 0) Expanded(child: OutlinedButton(onPressed: _prev, style: _pill, child: const Text('Précédent'))),
                if (_index > 0) const SizedBox(width: AppSpacing.s16),
                Expanded(child: FilledButton(onPressed: last ? () => Navigator.pop(context) : _next, child: Text(last ? 'Terminé' : 'Étape suivante'))),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle get _pill => OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        side: const BorderSide(color: AppColors.green),
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      );
}
