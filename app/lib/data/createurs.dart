import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth.dart';
import 'supabase_client.dart';

/// Créateurs Instagram / TikTok proposés par l'utilisateur.
///
/// Ce n'est pas un import : la proposition oriente la collecte, et chaque recette passe
/// ensuite par la réécriture complète. On ne promet donc jamais une mise en ligne, on dit
/// qu'on va regarder — et la fiche publiée ne portera ni le nom du créateur ni ses images.

enum Plateforme { instagram, tiktok }

extension PlateformeX on Plateforme {
  String get cle => name;
  String get nom => this == Plateforme.instagram ? 'Instagram' : 'TikTok';
}

enum StatutCreateur { nouveau, enCours, retenu, ecarte }

StatutCreateur _statut(String? s) => switch (s) {
      'en_cours' => StatutCreateur.enCours,
      'retenu' => StatutCreateur.retenu,
      'ecarte' => StatutCreateur.ecarte,
      _ => StatutCreateur.nouveau,
    };

class Createur {
  final String id;
  final Plateforme plateforme;
  final String handle;
  final String? note;
  final StatutCreateur statut;
  final DateTime creeLe;

  const Createur({
    required this.id,
    required this.plateforme,
    required this.handle,
    required this.statut,
    required this.creeLe,
    this.note,
  });

  factory Createur.fromRow(Map<String, dynamic> r) => Createur(
        id: r['id'].toString(),
        plateforme: r['plateforme'] == 'tiktok' ? Plateforme.tiktok : Plateforme.instagram,
        handle: r['handle']?.toString() ?? '',
        note: (r['note']?.toString().isEmpty ?? true) ? null : r['note'].toString(),
        statut: _statut(r['statut']?.toString()),
        creeLe: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
      );

  /// Ce qu'on montre à l'utilisateur sur l'avancement de sa proposition.
  String get etat => switch (statut) {
        StatutCreateur.nouveau => 'Proposé',
        StatutCreateur.enCours => 'En cours d’étude',
        StatutCreateur.retenu => 'Retenu',
        StatutCreateur.ecarte => 'Pas retenu',
      };
}

/// Résultat de l'analyse d'un lien ou d'un pseudo saisi par l'utilisateur.
class LienCreateur {
  final Plateforme? plateforme;
  final String? handle;
  final String? erreur;
  const LienCreateur({this.plateforme, this.handle, this.erreur});
  bool get valide => handle != null && plateforme != null;
}

/// Accepte un lien complet (profil, Reel, vidéo) ou un simple `@pseudo`.
/// La plateforme se déduit du lien ; pour un pseudo seul, l'appelant la fournit.
LienCreateur analyserLien(String saisie, {Plateforme? parDefaut}) {
  final texte = saisie.trim();
  if (texte.isEmpty) return const LienCreateur(erreur: 'Collez un lien ou un pseudo.');

  Plateforme? plateforme;
  String? brut;

  final uri = Uri.tryParse(texte.startsWith('http') ? texte : 'https://$texte');
  final hote = uri?.host.toLowerCase().replaceFirst('www.', '') ?? '';

  if (hote.contains('instagram.com')) {
    plateforme = Plateforme.instagram;
    // instagram.com/<pseudo>[/reel/xxx] — on écarte les chemins qui ne sont pas un profil.
    final seg = uri!.pathSegments.where((s) => s.isNotEmpty).toList();
    const nonProfil = {'p', 'reel', 'reels', 'tv', 'explore', 'stories', 'accounts'};
    brut = seg.isEmpty ? null : (nonProfil.contains(seg.first.toLowerCase()) ? null : seg.first);
    if (brut == null) {
      return const LienCreateur(
          erreur: 'Ce lien ne pointe pas vers un profil. Ouvrez le compte du créateur et copiez son lien.');
    }
  } else if (hote.contains('tiktok.com')) {
    plateforme = Plateforme.tiktok;
    final seg = uri!.pathSegments.where((s) => s.isNotEmpty).toList();
    final arobase = seg.where((s) => s.startsWith('@')).toList();
    brut = arobase.isNotEmpty ? arobase.first : null;
    if (brut == null) {
      return const LienCreateur(
          erreur: 'Ce lien ne pointe pas vers un profil. Ouvrez le compte du créateur et copiez son lien.');
    }
  } else if (!texte.contains('/') && !texte.contains('.com')) {
    plateforme = parDefaut;
    brut = texte;
  } else {
    return const LienCreateur(erreur: 'Seuls les liens Instagram et TikTok sont acceptés.');
  }

  final handle = brut.replaceAll('@', '').trim().toLowerCase();
  if (!RegExp(r'^[a-z0-9._]{1,30}$').hasMatch(handle)) {
    return const LienCreateur(erreur: 'Ce pseudo ne ressemble pas à un compte valide.');
  }
  if (plateforme == null) {
    return LienCreateur(handle: handle, erreur: 'Choisissez Instagram ou TikTok.');
  }
  return LienCreateur(plateforme: plateforme, handle: handle);
}

final mesCreateursProvider = FutureProvider<List<Createur>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final rows = await supabase
      .from('createurs_suggeres')
      .select()
      .eq('user_id', user.id)
      .order('created_at', ascending: false);
  return (rows as List).map((r) => Createur.fromRow(Map<String, dynamic>.from(r as Map))).toList();
});

class CreateursActions {
  final Ref ref;
  CreateursActions(this.ref);

  String? get _uid => ref.read(currentUserProvider)?.id;

  /// Renvoie null si la proposition est enregistrée, sinon un message pour l'utilisateur.
  Future<String?> proposer({required LienCreateur lien, String? note, String? url}) async {
    final uid = _uid;
    if (uid == null) return 'Créez un compte pour proposer un créateur.';
    if (!lien.valide) return lien.erreur ?? 'Lien invalide.';
    try {
      await supabase.from('createurs_suggeres').insert({
        'user_id': uid,
        'plateforme': lien.plateforme!.cle,
        'handle': lien.handle,
        if (url != null && url.isNotEmpty) 'url': url,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
      ref.invalidate(mesCreateursProvider);
      return null;
    } catch (e) {
      // La contrainte d'unicité est le cas courant : on le dit simplement.
      if (e.toString().contains('23505')) return 'Vous avez déjà proposé ce créateur.';
      return 'Impossible d’enregistrer pour le moment. Réessayez.';
    }
  }

  Future<void> retirer(String id) async {
    await supabase.from('createurs_suggeres').delete().eq('id', id);
    ref.invalidate(mesCreateursProvider);
  }
}

final createursActionsProvider = Provider<CreateursActions>((ref) => CreateursActions(ref));
