import 'package:flutter/material.dart';

// ─── Priority Enum ───────────────────────────────────────────
enum Priority { low, medium, high, urgent }

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.low:
        return 'Low';
      case Priority.medium:
        return 'Medium';
      case Priority.high:
        return 'High';
      case Priority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return const Color(0xFF4CAF50); // xanh lá
      case Priority.medium:
        return const Color(0xFF2196F3); // xanh dương
      case Priority.high:
        return const Color(0xFFFF9800); // cam
      case Priority.urgent:
        return const Color(0xFFF44336); // đỏ
    }
  }

  IconData get icon {
    switch (this) {
      case Priority.low:
        return Icons.flag_outlined;
      case Priority.medium:
        return Icons.flag;
      case Priority.high:
        return Icons.flag;
      case Priority.urgent:
        return Icons.flag;
    }
  }
}

// ─── Tag Model ───────────────────────────────────────────────
class TagModel {
  final String id;
  final String name;
  final Color color;

  const TagModel({required this.id, required this.name, required this.color});
}

// ─── Task Model ──────────────────────────────────────────────
class TaskModel {
  final String id;
  String title;
  String description;
  String category;
  TimeOfDay startTime;
  TimeOfDay endTime;
  DateTime date;
  Priority priority;
  List<TagModel> tags;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.priority = Priority.medium,
    this.tags = const [],
  });
}

class NoteModel {
  final int id;
  final String content;
  final bool pinned;

  NoteModel({
    required this.id,
    required this.content,
    this.pinned = false,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      content: json['content'] ?? '',
      pinned: json['pinned'] ?? false,
    );
  }
}