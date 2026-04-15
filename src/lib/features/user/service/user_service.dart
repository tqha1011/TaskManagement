import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/user_profile_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;
  /// Simulates fetching user profile data with a fake network delay
  Future<UserProfileModel> fetchUserProfile() async {
    // Mimic API call delay for smooth state switching
    try{
      final response = await _supabase.rpc('get_user_profile_stats');
      response['id'] = _supabase.auth.currentUser!.id;
      return UserProfileModel.fromJson(response);
    }
    catch(e){
      throw Exception("Failed to fetch user profile: $e");
    }
  }
}