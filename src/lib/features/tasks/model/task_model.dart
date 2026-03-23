import 'package:flutter/material.dart';

class TaskModel {
  final String id; // ID duy nhất để làm Hero tag và gọi API sau này
  String title;
  String description;
  String category;
  TimeOfDay startTime;
  TimeOfDay endTime;
  DateTime date;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.date,
  });
}