import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/user_profile_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;
  /// Simulates fetching user profile data with a fake network delay
  Future<UserProfileModel> fetchUserProfile() async {
    // Mimic API call delay for smooth state switching
    try{
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception("Không tìm thấy phiên đăng nhập. Hãy đăng nhập lại");
      }
      final response = await _supabase.rpc('get_user_profile_stats');
      if(response == null){
        throw Exception("Không thể lấy thông tin người dùng. Hãy thử lại sau");
      }
      response['id'] = _supabase.auth.currentUser!.id;
      return UserProfileModel.fromJson(response);
    }
    catch(e){
      throw Exception("Failed to fetch user profile: $e");
    }
  }
}