import 'dart:convert';

class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final parsedTimestamp =
        DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now();

    return ChatMessageModel(
      text: json['text']?.toString() ?? '',
      isUser: json['isUser'] as bool? ?? true,
      timestamp: parsedTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static String encodeList(List<ChatMessageModel> messages) {
    return jsonEncode(messages.map((message) => message.toJson()).toList());
  }

  static List<ChatMessageModel> decodeList(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => ChatMessageModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
