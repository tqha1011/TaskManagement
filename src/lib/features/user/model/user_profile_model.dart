import 'dart:convert';

class UserProfileModel {
  final String id;
  final String name;
  final int tasksDone;
  final int streaks;
  final String avatarUrl;
  bool isNotificationEnabled;
  String appearance;
  final Map<DateTime, int> heatmapData;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.tasksDone,
    required this.streaks,
    required this.avatarUrl,
    this.isNotificationEnabled = true,
    this.appearance = 'Light',
    required this.heatmapData,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    Map<DateTime, int> parseHeatmap = {};
    final rawHeatmapValue = json['heatmapData'] ?? json['heatmap_data'];
    Map<dynamic, dynamic>? rawHeatmap;
    if (rawHeatmapValue is Map) {
      rawHeatmap = rawHeatmapValue;
    } else if (rawHeatmapValue is String && rawHeatmapValue.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawHeatmapValue);
        if (decoded is Map) {
          rawHeatmap = decoded;
        }
      } catch (_) {
        // Ignore malformed JSON heatmap.
      }
    }

    if (rawHeatmap != null) {
      rawHeatmap.forEach((dateKey, count) {
        final dateString = dateKey?.toString();
        if (dateString == null || dateString.isEmpty) return;
        try {
          parseHeatmap[DateTime.parse(dateString)] = parseInt(count);
        } catch (_) {
          // Skip invalid date keys.
        }
      });
    }
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      name:
          (json['name'] ?? json['full_name'] ?? json['username']) as String? ??
          'Unknown User',
      tasksDone: parseInt(json['tasksDone'] ?? json['tasks_done']),
      streaks: parseInt(json['streaks'] ?? json['streak_count']),
      avatarUrl:
          (json['avatarUrl'] ?? json['avatar_url'] ?? json['avatar'])
              as String? ??
          '',
      isNotificationEnabled:
          (json['isNotificationEnabled'] ?? json['is_notification_enabled'])
              as bool? ??
          true,
      appearance:
          (json['appearance'] ?? json['theme_mode']) as String? ?? 'Light',

      heatmapData: parseHeatmap,
    );
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> heatmapJson = {};
    heatmapData.forEach((date, count) {
      heatmapJson[date.toIso8601String().split('T').first] = count;
    });
    return {
      'id': id,
      'name': name,
      'tasksDone': tasksDone,
      'streaks': streaks,
      'avatarUrl': avatarUrl,
      'isNotificationEnabled': isNotificationEnabled,
      'appearance': appearance,
      'heatmapData': heatmapJson,
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? name,
    int? tasksDone,
    int? streaks,
    String? avatarUrl,
    bool? isNotificationEnabled,
    String? appearance,
    Map<DateTime, int>? heatmapData,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tasksDone: tasksDone ?? this.tasksDone,
      streaks: streaks ?? this.streaks,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isNotificationEnabled:
          isNotificationEnabled ?? this.isNotificationEnabled,
      appearance: appearance ?? this.appearance,
      heatmapData: heatmapData ?? this.heatmapData,
    );
  }
}
