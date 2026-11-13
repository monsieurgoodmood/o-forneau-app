/// Minuteur du mode cuisine.
///
/// Il appartient à une ÉTAPE, pas à l'écran. L'audit du 13/11/2026 a relevé qu'en passant
/// à lL.of(context).etapeSuivantePuisEnRevenantLeun qui
/// relit l'étape précédente pendant que ça cuit perdait son minuteur.
///
/// Deuxième correction, invisible mais plus grave : le décompte se faisait en comptant les
/// battements d'une seconde. Un téléphone qui se verrouille suspend ces battements, et le
/// minuteur prenait du retard sans que personne ne le voie. On stocke donc une ÉCHÉANCE,
/// et on lit l'horloge.
class MinuteurEtape {
  DateTime? _echeance;
  int? _enPause; // secondes restantes au moment de la pause
  int? _etape;

  /// Pour les tests : permet de figer l'horloge.
  final DateTime Function() _maintenant;

  MinuteurEtape({DateTime Function()? horloge}) : _maintenant = horloge ?? DateTime.now;

  int? get etape => _etape;
  bool get arme => _echeance != null || _enPause != null;
  bool get enPause => _enPause != null;

  /// Secondes restantes, jamais négatives.
  int get restant {
    if (_enPause != null) return _enPause!;
    final fin = _echeance;
    if (fin == null) return 0;
    final s = fin.difference(_maintenant()).inSeconds;
    return s > 0 ? s : 0;
  }

  bool get termine => _echeance != null && _enPause == null && restant == 0;

  void lancer(int secondes, int etape) {
    if (secondes <= 0) return;
    _etape = etape;
    _enPause = null;
    _echeance = _maintenant().add(Duration(seconds: secondes));
  }

  void pause() {
    if (_echeance == null) return;
    _enPause = restant;
    _echeance = null;
  }

  void reprendre() {
    final reste = _enPause;
    if (reste == null) return;
    _enPause = null;
    _echeance = _maintenant().add(Duration(seconds: reste));
  }

  void arreter() {
    _echeance = null;
    _enPause = null;
    _etape = null;
  }

  /// Le minuteur tourne-t-il pour une autre étape que celle affichée ?
  bool ailleurs(int etapeAffichee) => arme && _etape != null && _etape != etapeAffichee;
}
