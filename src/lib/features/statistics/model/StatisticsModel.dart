import 'package:task_management_app/core/enum/TaskStatus.dart';

class RecentTaskModel{
  final int id;
  final String title;
  final DateTime updatedAt;
  final String? avatar;
  final TaskStatus status = TaskStatus.completed;

  RecentTaskModel({required this.id, required this.title, required this.updatedAt, required this.avatar});

  factory RecentTaskModel.fromJson(Map<String,dynamic> json){
    return RecentTaskModel(
        id: json['id'],
        title: json['title'] ?? '',
        updatedAt: DateTime.parse(json['updated_at']),
        avatar: json['avatar'],
    );
  }
}

class TodayStatsModel {
  final int total;
  final int completed;

  TodayStatsModel({
    required this.total,
    required this.completed,
  });

  factory TodayStatsModel.fromJson(Map<String, dynamic> json) {
    return TodayStatsModel(
      total: json['total'] ?? 0,
      completed: json['completed'] ?? 0,
    );
  }
}

class UserStatisticsModel {
  final TodayStatsModel today;
  final double todayCompletedPercentage;
  final int thisWeekTotal;
  final double growthPercentage;
  final List<RecentTaskModel> recentTasks;

  UserStatisticsModel({
    required this.today,
    required this.todayCompletedPercentage,
    required this.thisWeekTotal,
    required this.growthPercentage,
    required this.recentTasks,
  });

  // parse Json to UserStatisticsModel
  factory UserStatisticsModel.fromJson(Map<String, dynamic> json) {
    return UserStatisticsModel(
      today: TodayStatsModel.fromJson(json['today'] ?? {}),
      todayCompletedPercentage: (json['today_completed_percentage'] ?? 0).toDouble(),
      thisWeekTotal: json['this_week_total'] ?? 0,
      growthPercentage: (json['growth_percentage'] ?? 0).toDouble(),

      recentTasks: (json['recent_tasks'] as List<dynamic>?)
          ?.map((item) => RecentTaskModel.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}