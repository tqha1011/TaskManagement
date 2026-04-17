import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/category_model.dart';

class CategoryRepository {
  final SupabaseClient _client;

  CategoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<CategoryModel>> fetchCategories() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('category')
        .select('id, name, color_code, profile_id')
        .eq('profile_id', user.id)
        .order('name');

    return (rows as List<dynamic>)
        .map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

