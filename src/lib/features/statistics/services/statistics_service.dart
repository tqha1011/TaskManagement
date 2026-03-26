import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task_management_app/features/statistics/model/StatisticsModel.dart';

class StatisticsService {
  final SupabaseClient supabaseClient = Supabase.instance.client;

  Future<UserStatisticsModel> getUserStatistics(String userId) async {
    try{
      final response = await supabaseClient.rpc('get_user_statistics',params: {'p_profile_id' : userId});
      return UserStatisticsModel.fromJson(response);
    }
    catch(e){
      throw Exception('Failed to get statistics: $e');
    }
  }
}