class ChatSessionModel {
  final String id;
  final String title;
  final String profileId;
  final DateTime createdAt;

  ChatSessionModel({
    required this.id,
    required this.title,
    required this.profileId,
    required this.createdAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'].toString(),
      title: json['title'] ?? 'Cuộc trò chuyện mới',
      profileId: json['profile_id'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'profile_id': profileId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
