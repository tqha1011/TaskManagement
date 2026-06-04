class ChatMessageModel {
  final String? id;
  final String? sessionId;
  final String role; // 'user' or 'model'
  final String content;
  final DateTime timestamp;

  ChatMessageModel({
    this.id,
    this.sessionId,
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString(),
      sessionId: json['session_id']?.toString(),
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      timestamp: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'created_at': timestamp.toIso8601String(),
    };
  }
}
