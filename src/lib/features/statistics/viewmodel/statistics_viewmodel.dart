import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:task_management_app/features/statistics/model/StatisticsModel.dart';
import 'package:task_management_app/features/statistics/services/statistics_service.dart';

class StatisticsViewmodel extends ChangeNotifier{
  final StatisticsService statisticsService = StatisticsService();

  bool _isLoading = false;
  String? _errorMessage;
  UserStatisticsModel? statisticsData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> getStatisticsData(String userId) async{
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try{
      statisticsData = await statisticsService.getUserStatistics(userId);
    }
    catch(e){
      _errorMessage = e.toString();
    }
    finally{
      _isLoading = false;
      notifyListeners();
    }
  }
}