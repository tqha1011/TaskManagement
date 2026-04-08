import 'dart:convert';

class NoteModel {
  final String id;
  final String content;
  final bool pinned;
  final String? imagePath;

  NoteModel({
    required this.id,
    required this.content,
    this.pinned = false,
    this.imagePath,
  });

  // --- LOCAL STORAGE HELPERS ---

  // Convert Object to Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'pinned': pinned,
      'imagePath': imagePath,
    };
  }

  // Create Object from Map
  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      content: map['content'],
      pinned: map['pinned'] ?? false,
      imagePath: map['imagePath'],
    );
  }

  // JSON Helpers for SharedPreferences
  String toJson() => json.encode(toMap());
  factory NoteModel.fromJson(String source) => NoteModel.fromMap(json.decode(source));
}