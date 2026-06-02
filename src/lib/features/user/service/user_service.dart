import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/user_profile_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;
  /// Simulates fetching user profile data with a fake network delay
  Future<UserProfileModel> fetchUserProfile({int days = 90}) async {
    // Mimic API call delay for smooth state switching
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception("Không tìm thấy phiên đăng nhập. Hãy đăng nhập lại");
      }
      final response = await _supabase.rpc(
        'get_user_profile_stats',
        params: {'p_days': days},
      );
      if (response == null) {
        throw Exception("Không thể lấy thông tin người dùng. Hãy thử lại sau");
      }

      dynamic data = response;
      if (response is PostgrestResponse) {
        data = response.data;
      }

      Map<String, dynamic> payload;
      if (data is Map<String, dynamic>) {
        payload = data;
      } else if (data is Map) {
        payload = Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        payload = Map<String, dynamic>.from(data.first as Map);
      } else {
        throw Exception('Phản hồi không hợp lệ: ${data.runtimeType}');
      }

      payload['id'] = user.id;
      return UserProfileModel.fromJson(payload);
    } catch (e) {
      throw Exception("Failed to fetch user profile: $e");
    }
  }
}