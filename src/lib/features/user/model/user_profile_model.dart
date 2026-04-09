class UserProfileModel {
  final String id;
  final String name;
  final int tasksDone;
  final int streaks;
  final String avatarUrl;
  bool isNotificationEnabled;
  String appearance;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.tasksDone,
    required this.streaks,
    required this.avatarUrl,
    this.isNotificationEnabled = true,
    this.appearance = 'Light',
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      // Dùng as String? để ép kiểu an toàn, kèm ?? để gán giá trị mặc định nếu bị null
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown User',
      tasksDone: json['tasksDone'] as int? ?? 0,
      streaks: json['streaks'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isNotificationEnabled: json['isNotificationEnabled'] as bool? ?? true,
      appearance: json['appearance'] as String? ?? 'Light',
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tasksDone': tasksDone,
      'streaks': streaks,
      'avatarUrl': avatarUrl,
      'isNotificationEnabled': isNotificationEnabled,
      'appearance': appearance,
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
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tasksDone: tasksDone ?? this.tasksDone,
      streaks: streaks ?? this.streaks,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      appearance: appearance ?? this.appearance,
    );
  }
}