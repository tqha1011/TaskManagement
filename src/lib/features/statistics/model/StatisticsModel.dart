import 'package:task_management_app/core/enum/TaskStatus.dart';

class RecentTaskModel{
  final int id;
  final String title;
  final DateTime updatedAt;
  final String? avatar;
  final TaskStatus status = TaskStatus.completed;

  RecentTaskModel({required this.id, required this.title, required this.updatedAt, required this.avatar});

  static DateTime _toVietnamTime(DateTime value) {
    final utcValue = value.isUtc ? value : value.toUtc();
    return utcValue.add(const Duration(hours: 7));
  }

  factory RecentTaskModel.fromJson(Map<String,dynamic> json){
    final parsed = DateTime.parse(json['updated_at']);
    return RecentTaskModel(
        id: json['id'],
        title: json['title'] ?? '',
        updatedAt: _toVietnamTime(parsed),
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
  final List<int> dailyCounts;

  UserStatisticsModel({
    required this.today,
    required this.todayCompletedPercentage,
    required this.thisWeekTotal,
    required this.growthPercentage,
    required this.recentTasks,
    required this.dailyCounts,
  });

  factory UserStatisticsModel.fromJson(Map<String, dynamic> json) {
    return UserStatisticsModel(
      today: TodayStatsModel.fromJson(json['today'] ?? {}),
      todayCompletedPercentage: (json['today_completed_percentage'] ?? 0).toDouble(),
      thisWeekTotal: json['this_week_total'] ?? 0,
      growthPercentage: (json['growth_percentage'] ?? 0).toDouble(),
      recentTasks: (json['recent_tasks'] as List<dynamic>?)
          ?.map((item) => RecentTaskModel.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      dailyCounts: List<int>.from(json['daily_counts'] ?? [0, 0, 0, 0, 0, 0, 0]),
    );
  }
}