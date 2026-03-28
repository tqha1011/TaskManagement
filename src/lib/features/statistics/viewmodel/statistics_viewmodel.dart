import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:task_management_app/features/statistics/model/StatisticsModel.dart';
import 'package:task_management_app/features/statistics/services/statistics_service.dart';

class StatisticsViewmodel extends ChangeNotifier {
  final StatisticsService statisticsService = StatisticsService();

  bool _isLoading = false;
  String? _errorMessage;
  UserStatisticsModel? statisticsData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;


  List<double> get weeklyBarHeights {

    if (statisticsData == null) return List.filled(7, 0.1);

    List<int> rawCounts = statisticsData!.dailyCounts;


    int maxTasks = rawCounts.reduce((curr, next) => curr > next ? curr : next);
    if (maxTasks == 0) return List.filled(7, 0.1);


    return rawCounts.map((count) => count / maxTasks).toList();
  }

  Future<void> getStatisticsData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      statisticsData = await statisticsService.getUserStatistics(userId);
    } catch (e) {
      _errorMessage = e.toString();

      debugPrint("Error fetching statistics: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}