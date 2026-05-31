import 'package:flutter/material.dart';

import 'package:task_management_app/features/category/model/category_model.dart';
import 'package:task_management_app/features/tag/model/tag_model.dart';

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

// ─── Task Model ──────────────────────────────────────────────
class TaskModel {
  final String id;
  String title;
  String description;
  CategoryModel category;
  TimeOfDay startTime;
  TimeOfDay endTime;
  DateTime date;
  Priority priority;
  List<TagModel> tags;
  final int totalSubtasks;
  final int completedSubtasks;
  final int? templateId;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.totalSubtasks = 0,
    this.completedSubtasks = 0,
    this.priority = Priority.medium,
    this.tags = const [],
    this.templateId,
  });

  factory TaskModel.fromMap(Map<String, dynamic> map) {

    DateTime startDate = map['start_time'] != null 
        ? DateTime.parse(map['start_time']).toLocal() 
        : DateTime.now();
    DateTime dueDate = map['due_time'] != null 
        ? DateTime.parse(map['due_time']).toLocal() 
        : DateTime.now();

    return TaskModel(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      templateId: map['template_id'], 


      category: CategoryModel(
        id: map['category']['id'] ?? 0,
        name: map['category']['name'] ?? 'No Name',
        colorCode: map['category']['colorCode'] ?? '0xFF9E9E9E',
        profileId: map['category']['profileId'] ?? '',          
      ),


      tags: (map['task_tags'] as List? ?? []).map((t) {
        final tagData = t['tags'];
        return TagModel(
          id: tagData['id'],
          name: tagData['name'] ?? '',
          colorCode: tagData['color'] ?? '0xFFFFFFFF', 
          profileId: tagData['profile_id'],
        );
      }).toList(),

      date: startDate,
      startTime: TimeOfDay.fromDateTime(startDate),
      endTime: TimeOfDay.fromDateTime(dueDate),
      priority: _parsePriority(map['priority']),
      totalSubtasks: map['total_subtasks'] ?? 0,
      completedSubtasks: map['completed_subtasks'] ?? 0,
    );
  }

  static Priority _parsePriority(int? p) {
    switch (p) {
      case 1: return Priority.urgent;
      case 2: return Priority.high;
      case 3: return Priority.medium;
      case 4: return Priority.low;
      default: return Priority.medium;
    }
  }
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