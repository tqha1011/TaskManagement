import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/tag_model.dart';

class TagRepository {
  final SupabaseClient _client;

  TagRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<TagModel>> fetchTags() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('tag')
        .select('id, name, color_code, profile_id')
        .eq('profile_id', user.id)
        .order('name');

    return (rows as List<dynamic>)
        .map((e) => TagModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<TagModel> createCustomTag(String name, String colorCode) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final inserted = await _client
        .from('tag')
        .insert({
          'name': name,
          'color_code': colorCode,
          'profile_id': user.id,
        })
        .select('id, name, color_code, profile_id')
        .single();

    return TagModel.fromJson(Map<String, dynamic>.from(inserted));
  }
}

