import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth.dart';
import 'recipe.dart';
import 'recipes_repository.dart';
import 'supabase_client.dart';

/// Programme nutritionnel + foyer — port 1:1 de la logique web (GOALS, DIETPLANS, Mifflin-St Jeor,
/// foyerDiets, pickMeal, buildPlan). Persistance locale (mf_prog / mf_foyer) + cloud app_state.

class Goal {
  final String label, sub;
  final double f;
  final int base;
  const Goal(this.label, this.sub, this.f, this.base);
}

const Map<String, Goal> kGoals = {
  'perte': Goal('Perte de poids', 'déficit ~20 %', 0.8, 1600),
  'maintien': Goal('Maintien', 'équilibre', 1.0, 2000),
  'masse': Goal('Prise de masse', 'surplus ~15 %', 1.15, 2550),
};

class DietPlan {
  final String label;
  final int p, l, g; // % des kcal
  final String? filter;
  const DietPlan(this.label, this.p, this.l, this.g, [this.filter]);
}

const Map<String, DietPlan> kDietPlans = {
  'equilibre': DietPlan('Équilibré', 25, 30, 45),
  'proteine': DietPlan('Hyperprotéiné', 40, 25, 35, 'proteine'),
  'lowcarb': DietPlan('Low carb', 30, 45, 25, 'lowcarb'),
  'keto': DietPlan('Keto', 25, 70, 5, 'keto'),
  'mediterraneen': DietPlan('Méditerranéen', 20, 35, 45),
  'vegetarien': DietPlan('Végétarien', 22, 30, 48, 'vegetarien'),
  'vegan': DietPlan('100 % végétal', 20, 30, 50, 'vegan'),
};

class Activity {
  final String label;
  final double f;
  const Activity(this.label, this.f);
}

const Map<String, Activity> kActivities = {
  'sedentaire': Activity('Sédentaire', 1.2),
  'leger': Activity('Peu actif', 1.375),
  'modere': Activity('Actif', 1.55),
  'intense': Activity('Très actif', 1.725),
};

/// Membre du foyer (et profil « solo » du programme : mêmes champs + objectif).
class Member {
  final String sexe; // 'f' | 'h'
  final int age, taille, poids;
  final String act, diet;
  const Member({this.sexe = 'f', this.age = 0, this.taille = 0, this.poids = 0, this.act = 'modere', this.diet = 'equilibre'});

  Member copyWith({String? sexe, int? age, int? taille, int? poids, String? act, String? diet}) => Member(
      sexe: sexe ?? this.sexe, age: age ?? this.age, taille: taille ?? this.taille, poids: poids ?? this.poids,
      act: act ?? this.act, diet: diet ?? this.diet);

  Map<String, dynamic> toJson() => {'sexe': sexe, 'age': age, 'taille': taille, 'poids': poids, 'act': act, 'diet': diet};
  factory Member.fromJson(Map m) => Member(
        sexe: m['sexe']?.toString() ?? 'f',
        age: _i(m['age']), taille: _i(m['taille']), poids: _i(m['poids']),
        act: m['act']?.toString() ?? 'modere', diet: m['diet']?.toString() ?? 'equilibre');
  static int _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  /// Dépense estimée (Mifflin-St Jeor × activité), arrondie à 10. 0 si profil incomplet.
  int get kcal {
    if (!(poids > 0 && taille > 0 && age > 0)) return 0;
    final bmr = 10 * poids + 6.25 * taille - 5 * age + (sexe == 'h' ? 5 : -161);
    final f = (kActivities[act] ?? kActivities['modere']!).f;
    return ((bmr * f) / 10).round() * 10;
  }
}

class Prog {
  final Member me;
  final String goal;
  const Prog({this.me = const Member(), this.goal = 'maintien'});
  Prog copyWith({Member? me, String? goal}) => Prog(me: me ?? this.me, goal: goal ?? this.goal);
  Map<String, dynamic> toJson() => {...me.toJson(), 'goal': goal};
  factory Prog.fromJson(Map m) => Prog(me: Member.fromJson(m), goal: m['goal']?.toString() ?? 'maintien');
}

class Foyer {
  final String mode; // 'solo' | 'famille'
  final int count;
  final List<Member> members;
  const Foyer({this.mode = 'solo', this.count = 2, this.members = const []});
  Foyer copyWith({String? mode, int? count, List<Member>? members}) =>
      Foyer(mode: mode ?? this.mode, count: count ?? this.count, members: members ?? this.members);
  int get effectiveCount => mode == 'solo' ? 1 : count.clamp(1, 12);
  Map<String, dynamic> toJson() => {'mode': mode, 'count': count, 'members': members.map((m) => m.toJson()).toList()};
  factory Foyer.fromJson(Map m) => Foyer(
        mode: m['mode']?.toString() ?? 'solo',
        count: Member._i(m['count']) == 0 ? 2 : Member._i(m['count']),
        members: (m['members'] is List) ? (m['members'] as List).whereType<Map>().map(Member.fromJson).toList() : const [],
      );
}

class Target {
  final int kcal, tdee, p, l, g;
  final DietPlan plan;
  const Target(this.kcal, this.tdee, this.p, this.l, this.g, this.plan);
}

Target progTarget(Prog prog) {
  final goal = kGoals[prog.goal] ?? kGoals['maintien']!;
  final tdee = prog.me.kcal;
  final kcal = tdee > 0 ? ((tdee * goal.f) / 10).round() * 10 : goal.base;
  final d = kDietPlans[prog.me.diet] ?? kDietPlans['equilibre']!;
  return Target(kcal, tdee, (kcal * d.p / 100 / 4).round(), (kcal * d.l / 100 / 9).round(), (kcal * d.g / 100 / 4).round(), d);
}

double _carbShare(Recipe r) => r.macros == null ? 1 : (r.macros!.g * 4) / (r.macros!.kcal < 1 ? 1 : r.macros!.kcal);
double _protShare(Recipe r) => r.macros == null ? 0 : (r.macros!.p * 4) / (r.macros!.kcal < 1 ? 1 : r.macros!.kcal);

bool recipeMatchesDiet(Recipe r, String diet) {
  final f = kDietPlans[diet]?.filter;
  if (f == null) return true;
  switch (f) {
    case 'vegetarien': return r.diets.contains('vegetarien');
    case 'vegan': return r.diets.contains('vegan');
    case 'keto': return r.macros != null && _carbShare(r) < 0.22;
    case 'lowcarb': return r.macros != null && _carbShare(r) < 0.38;
    case 'proteine': return r.macros != null && _protShare(r) > 0.25;
  }
  return true;
}

bool recipeMatchesAll(Recipe r, List<String> diets) => diets.every((d) => recipeMatchesDiet(r, d));

/// Régimes à satisfaire : ceux de CHAQUE membre (intersection) en mode famille, sinon celui du profil.
List<String> foyerDiets(Foyer foyer, Prog prog) {
  if (foyer.mode != 'solo') {
    final ds = foyer.members.map((m) => m.diet).where((d) => d.isNotEmpty).toSet().toList();
    if (ds.isNotEmpty) return ds;
  }
  return [prog.me.diet];
}

Recipe? pickMeal(List<Recipe> all, String cat, int off, List<String> diets, int seed) {
  var pool = all.where((r) => r.macros != null && r.meal.contains(cat) && recipeMatchesAll(r, diets)).toList();
  if (pool.isEmpty) pool = all.where((r) => r.macros != null && r.meal.contains(cat)).toList();
  if (pool.isEmpty) pool = all.where((r) => r.macros != null && recipeMatchesAll(r, diets)).toList();
  if (pool.isEmpty) pool = all.where((r) => r.macros != null).toList();
  if (pool.isEmpty) return all.isEmpty ? null : all.first;
  return pool[(seed + off) % pool.length];
}

class PlanItem {
  final String label;
  final Recipe recipe;
  const PlanItem(this.label, this.recipe);
}

List<PlanItem> buildPlan(List<Recipe> all, List<String> diets, int seed, {bool gouter = false}) {
  final out = <PlanItem>[];
  void add(String l, String cat, int off) {
    final r = pickMeal(all, cat, off, diets, seed);
    if (r != null) out.add(PlanItem(l, r));
  }
  add('Petit-déjeuner', 'petit-dej', 0);
  add('Déjeuner', 'dejeuner', 0);
  add('Dîner', 'diner', 1);
  if (gouter) add('Goûter', 'gouter', 0);
  return out;
}

// ---------- Persistance (locale + cloud app_state, même clés que le web) ----------

Future<void> _cloudMerge(Ref ref, String key, Map<String, dynamic> value) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;
  try {
    final row = await supabase.from('user_profiles').select('app_state').eq('id', user.id).maybeSingle();
    final st = Map<String, dynamic>.from((row?['app_state'] is Map) ? row!['app_state'] as Map : {});
    st[key] = value;
    await supabase.from('user_profiles').update({'app_state': st}).eq('id', user.id);
  } catch (_) {}
}

class ProgNotifier extends StateNotifier<Prog> {
  final SharedPreferences _p;
  final Ref _ref;
  ProgNotifier(this._p, this._ref) : super(_load(_p));
  static Prog _load(SharedPreferences p) {
    try { final raw = p.getString('mf_prog'); if (raw != null) return Prog.fromJson(jsonDecode(raw) as Map); } catch (_) {}
    return const Prog();
  }
  Future<void> set(Prog v) async {
    state = v;
    await _p.setString('mf_prog', jsonEncode(v.toJson()));
    _cloudMerge(_ref, 'prog', v.toJson());
  }
}

class FoyerNotifier extends StateNotifier<Foyer> {
  final SharedPreferences _p;
  final Ref _ref;
  FoyerNotifier(this._p, this._ref) : super(_load(_p));
  static Foyer _load(SharedPreferences p) {
    try { final raw = p.getString('mf_foyer'); if (raw != null) return Foyer.fromJson(jsonDecode(raw) as Map); } catch (_) {}
    return const Foyer();
  }
  Future<void> set(Foyer v) async {
    // Aligne la liste des membres sur le nombre demandé (comme syncMembers côté web).
    final n = v.effectiveCount;
    final members = List<Member>.from(v.members);
    while (members.length < n) { members.add(const Member()); }
    if (members.length > n) members.length = n;
    state = v.copyWith(members: members);
    await _p.setString('mf_foyer', jsonEncode(state.toJson()));
    _cloudMerge(_ref, 'foyer', state.toJson());
  }
}

final progProvider = StateNotifierProvider<ProgNotifier, Prog>((ref) => ProgNotifier(ref.watch(prefsProvider), ref));
final foyerProvider = StateNotifierProvider<FoyerNotifier, Foyer>((ref) => FoyerNotifier(ref.watch(prefsProvider), ref));
final menuSeedProvider = StateProvider<int>((ref) => 1);
final gouterProvider = StateProvider<bool>((ref) => false);

/// Menu du jour compatible avec tous les régimes du foyer.
final dailyPlanProvider = Provider<List<PlanItem>>((ref) {
  final all = ref.watch(recipesProvider).asData?.value ?? const <Recipe>[];
  final diets = foyerDiets(ref.watch(foyerProvider), ref.watch(progProvider));
  return buildPlan(all, diets, ref.watch(menuSeedProvider), gouter: ref.watch(gouterProvider));
});
