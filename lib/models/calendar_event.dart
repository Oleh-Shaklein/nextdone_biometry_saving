import 'package:flutter/material.dart';

enum TaskType { reminder, habit, checklist }

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime; // коли показати
  final TaskType type;
  final List<ChecklistItem>? checklistItems;
  final TimeOfDay? reminderTime;
  final Duration? repeatInterval;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.type,
    this.checklistItems,
    this.reminderTime,
    this.repeatInterval,
  });
}

class ChecklistItem {
  final String id;
  String text;
  List<ChecklistItem> subItems;
  DateTime? deadline;

  ChecklistItem({
    required this.id,
    required this.text,
    this.subItems = const [],
    this.deadline,
  });
}