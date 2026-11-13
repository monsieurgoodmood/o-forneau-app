import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/auth.dart';
import '../../l10n/app_localizations.dart';

enum AuthMode { signup, login }

class AuthScreen extends ConsumerStatefulWidget {
  final AuthMode mode;
  const AuthScreen({super.key, required this.mode});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late AuthMode _mode = widget.mode;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _tel = TextEditingController();
  bool _marketing = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _prenom.dispose();
    _nom.dispose();
    _tel.dispose();
    super.dispose();
  }

  bool get _isSignup => _mode == AuthMode.signup;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final actions = ref.read(authActionsProvider);
      if (_isSignup) {
        if (_prenom.text.trim().isEmpty) throw L.of(context).votrePrenomEstRequis;
        await actions.signUp(
          email: _email.text.trim(),
          password: _password.text,
          prenom: _prenom.text.trim(),
          nom: _nom.text.trim(),
          telephone: _tel.text.trim(),
          marketing: _marketing,
        );
      } else {
        await actions.signIn(email: _email.text.trim(), password: _password.text);
      }
      if (mounted && (ref.read(currentUserProvider) != null)) {
        Navigator.of(context).pop();
      } else if (mounted && _isSignup) {
        // Si confirmation e-mail requise, pas de session immédiate.
        setState(() => _error = L.of(context).compteCreeVerifiezVosEMails);
      }
    } catch (e) {
      setState(() => _error = e is String ? e : _pretty(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _pretty(String raw) {
    if (raw.contains(L.of(context).invalidLogin)) return L.of(context).eMailOuMotDePasse;
    if (raw.contains(L.of(context).alreadyRegistered)) return L.of(context).unCompteExisteDejaAvecCet;
    if (raw.contains(L.of(context).passwordShould)) return L.of(context).motDePasseTropCourt6;
    return L.of(context).uneErreurEstSurvenueReessayez;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.greenDeep,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.s24, 0, AppSpacing.s24, AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_isSignup ? L.of(context).creerMonCompte : L.of(context).connexion,
                  style: t.textTheme.displaySmall?.copyWith(color: AppColors.greenDeep)),
              const SizedBox(height: AppSpacing.s24),
              if (_isSignup) ...[
                _field(_prenom, 'Prénom', TextInputType.name),
                _field(_nom, L.of(context).nomFacultatif, TextInputType.name),
              ],
              _field(_email, 'E-mail', TextInputType.emailAddress),
              _field(_password, L.of(context).motDePasse, TextInputType.visiblePassword, obscure: true),
              if (_isSignup) ...[
                _field(_tel, L.of(context).telephoneFacultatif, TextInputType.phone),
                const SizedBox(height: AppSpacing.s8),
                CheckboxListTile(
                  value: _marketing,
                  onChanged: (v) => setState(() => _marketing = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.green,
                  title: Text(L.of(context).jeSouhaiteRecevoirLesRecettesEt, style: t.textTheme.bodyMedium),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(_error!, style: t.textTheme.bodyMedium?.copyWith(color: AppColors.danger)),
              ],
              const SizedBox(height: AppSpacing.s24),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isSignup ? L.of(context).creerMonCompte : L.of(context).seConnecter),
              ),
              const SizedBox(height: AppSpacing.s16),
              TextButton(
                onPressed: _busy ? null : () => setState(() { _mode = _isSignup ? AuthMode.login : AuthMode.signup; _error = null; }),
                child: Text(
                  _isSignup ? L.of(context).jAiDejaUnCompte : L.of(context).creerUnCompte,
                  style: t.textTheme.labelLarge?.copyWith(color: AppColors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, TextInputType kind, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: TextField(
        controller: c,
        keyboardType: kind,
        obscureText: obscure,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.r16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.r16), borderSide: const BorderSide(color: AppColors.green)),
        ),
      ),
    );
  }
}
