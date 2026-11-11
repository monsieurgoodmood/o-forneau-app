import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import 'auth.dart';
import 'supabase_client.dart';

/// Agrégats publics d'une recette (table recipe_stats, lisible par la clé anon).
class RecipeStats {
  final double avg;
  final int count;
  final int commentCount;
  final double avgTaste;
  final double avgEase;
  final double avgVisual;
  final int photoCount;
  const RecipeStats({
    this.avg = 0, this.count = 0, this.commentCount = 0,
    this.avgTaste = 0, this.avgEase = 0, this.avgVisual = 0, this.photoCount = 0,
  });
  static const empty = RecipeStats();
  factory RecipeStats.fromRow(Map<String, dynamic> r) {
    double d(String k) => (r[k] is num) ? (r[k] as num).toDouble() : 0;
    int i(String k) => (r[k] is num) ? (r[k] as num).toInt() : 0;
    return RecipeStats(
      avg: d('avg_rating'), count: i('rating_count'), commentCount: i('comment_count'),
      avgTaste: d('avg_taste'), avgEase: d('avg_ease'), avgVisual: d('avg_visual'), photoCount: i('photo_count'),
    );
  }
}

class MyRating {
  final int? taste, ease, visual;
  const MyRating({this.taste, this.ease, this.visual});
}

class RecipeComment {
  final String id, slug, userId, body;
  final String? author;
  final DateTime createdAt;
  const RecipeComment({required this.id, required this.slug, required this.userId, required this.body, this.author, required this.createdAt});
  factory RecipeComment.fromRow(Map<String, dynamic> r) => RecipeComment(
        id: r['id'].toString(), slug: r['recipe_slug'].toString(), userId: r['user_id'].toString(),
        body: r['body']?.toString() ?? '', author: r['author_name']?.toString(),
        createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class RecipePhoto {
  final String id, slug, userId, path;
  final String? author;
  final DateTime createdAt;
  const RecipePhoto({required this.id, required this.slug, required this.userId, required this.path, this.author, required this.createdAt});
  factory RecipePhoto.fromRow(Map<String, dynamic> r) => RecipePhoto(
        id: r['id'].toString(), slug: r['recipe_slug'].toString(), userId: r['user_id'].toString(),
        path: r['path'].toString(), author: r['author_name']?.toString(),
        createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
  String get url => supabase.storage.from('dish-photos').getPublicUrl(path);
}

/// Toutes les stats en une requête (≤ 406 lignes) → badge sur les cartes + tri « mieux notées ».
final statsMapProvider = FutureProvider<Map<String, RecipeStats>>((ref) async {
  try {
    final rows = await supabase.from('recipe_stats').select();
    return {for (final r in (rows as List)) r['recipe_slug'].toString(): RecipeStats.fromRow(Map<String, dynamic>.from(r))};
  } catch (_) {
    return const {};
  }
});

final statsOfProvider = Provider.family<RecipeStats, String>((ref, slug) =>
    ref.watch(statsMapProvider).asData?.value[slug] ?? RecipeStats.empty);

final myRatingProvider = FutureProvider.family<MyRating?, String>((ref, slug) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final r = await supabase.from('recipe_ratings').select('taste,ease,visual').eq('recipe_slug', slug).eq('user_id', user.id).maybeSingle();
  if (r == null) return null;
  return MyRating(taste: r['taste'] as int?, ease: r['ease'] as int?, visual: r['visual'] as int?);
});

final commentsProvider = FutureProvider.family<List<RecipeComment>, String>((ref, slug) async {
  final rows = await supabase.from('recipe_comments').select().eq('recipe_slug', slug).order('created_at', ascending: false).limit(100);
  return (rows as List).map((r) => RecipeComment.fromRow(Map<String, dynamic>.from(r))).toList();
});

final photosProvider = FutureProvider.family<List<RecipePhoto>, String>((ref, slug) async {
  final rows = await supabase.from('recipe_photos').select().eq('recipe_slug', slug).order('created_at', ascending: false).limit(60);
  return (rows as List).map((r) => RecipePhoto.fromRow(Map<String, dynamic>.from(r))).toList();
});

/// Actions communauté (toutes exigent une session ; la RLS garantit « ses propres contenus »).
class CommunityActions {
  final Ref ref;
  CommunityActions(this.ref);

  String get _uid => supabase.auth.currentUser!.id;
  String? get _author => supabase.auth.currentUser?.userMetadata?['prenom']?.toString();

  /// stars = moyenne arrondie des critères renseignés (même règle que le web).
  Future<void> submitRating(String slug, {int? taste, int? ease, int? visual}) async {
    final vals = [taste, ease, visual].whereType<int>().toList();
    if (vals.isEmpty) return;
    final stars = (vals.reduce((a, b) => a + b) / vals.length).round().clamp(1, 5);
    await supabase.from('recipe_ratings').upsert({
      'recipe_slug': slug, 'user_id': _uid, 'stars': stars,
      'taste': taste, 'ease': ease, 'visual': visual, 'updated_at': DateTime.now().toIso8601String(),
    });
    ref.invalidate(myRatingProvider(slug));
    ref.invalidate(statsMapProvider);
  }

  Future<void> addComment(String slug, String body) async {
    final text = body.trim();
    if (text.isEmpty) return;
    await supabase.from('recipe_comments').insert({
      'recipe_slug': slug, 'user_id': _uid, 'author_name': _author, 'body': text.length > 1000 ? text.substring(0, 1000) : text,
    });
    ref.invalidate(commentsProvider(slug));
    ref.invalidate(statsMapProvider);
  }

  Future<void> deleteComment(String slug, String id) async {
    await supabase.from('recipe_comments').delete().eq('id', id);
    ref.invalidate(commentsProvider(slug));
    ref.invalidate(statsMapProvider);
  }

  Future<void> reportComment(String slug, String id) async {
    await supabase.rpc('report_comment', params: {'p_id': id});
    ref.invalidate(commentsProvider(slug));
  }

  /// Photo compressée côté natif (1280 px, qualité 82 — comme le web) puis upload dans <uid>/<slug>-<ts>.jpg.
  Future<void> uploadPhoto(String slug, XFile file) async {
    final bytes = await file.readAsBytes();
    final path = '$_uid/$slug-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await supabase.storage.from('dish-photos').uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
    await supabase.from('recipe_photos').insert({'recipe_slug': slug, 'user_id': _uid, 'author_name': _author, 'path': path});
    ref.invalidate(photosProvider(slug));
    ref.invalidate(statsMapProvider);
  }

  Future<void> deletePhoto(String slug, RecipePhoto p) async {
    await supabase.from('recipe_photos').delete().eq('id', p.id);
    try { await supabase.storage.from('dish-photos').remove([p.path]); } catch (_) {}
    ref.invalidate(photosProvider(slug));
    ref.invalidate(statsMapProvider);
  }

  Future<void> reportPhoto(String slug, String id) async {
    await supabase.rpc('report_photo', params: {'p_id': id});
    ref.invalidate(photosProvider(slug));
  }

  Future<XFile?> pickPhoto({required bool camera}) => ImagePicker().pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1280, maxHeight: 1280, imageQuality: 82,
      );
}

final communityActionsProvider = Provider<CommunityActions>((ref) => CommunityActions(ref));
