import 'package:flutter/material.dart';

enum TaskType { reminder, habit, checklist }

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final TaskType type;
  final List<ChecklistItem>? checklistItems;

  final TimeOfDay? reminderTime;
  final Duration? repeatInterval;

  bool isImportant;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    this.checklistItems,
    this.reminderTime,
    this.repeatInterval,
    this.isImportant = false,
    this.isDone = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    TaskType? type,
    List<ChecklistItem>? checklistItems,
    TimeOfDay? reminderTime,
    Duration? repeatInterval,
    bool? isImportant,
    bool? isDone,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      checklistItems: checklistItems ?? this.checklistItems,
      reminderTime: reminderTime ?? this.reminderTime,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      isImportant: isImportant ?? this.isImportant,
      isDone: isDone ?? this.isDone,
    );
  }

  /// Convert Task to Map for storing (JSON serializable).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': _taskTypeToString(type),
      'checklistItems': checklistItems?.map((e) => e.toJson()).toList(),
      'reminderTime': reminderTime != null ? {'hour': reminderTime!.hour, 'minute': reminderTime!.minute} : null,
      'repeatIntervalMillis': repeatInterval?.inMilliseconds,
      'isImportant': isImportant,
      'isDone': isDone,
    };
  }

  /// Create Task from stored Map.
  factory Task.fromJson(Map<String, dynamic> json) {
    final checklistRaw = json['checklistItems'] as List<dynamic>?;
    List<ChecklistItem>? checklist;
    if (checklistRaw != null) {
      checklist = checklistRaw.map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    }

    final reminderMap = json['reminderTime'] as Map<String, dynamic>?;
    TimeOfDay? reminder;
    if (reminderMap != null) {
      final h = (reminderMap['hour'] is int) ? reminderMap['hour'] as int : int.parse(reminderMap['hour'].toString());
      final m = (reminderMap['minute'] is int) ? reminderMap['minute'] as int : int.parse(reminderMap['minute'].toString());
      reminder = TimeOfDay(hour: h, minute: m);
    }

    final repeatMillis = json['repeatIntervalMillis'];
    Duration? repeat;
    if (repeatMillis != null) {
      repeat = Duration(milliseconds: (repeatMillis is int) ? repeatMillis : int.parse(repeatMillis.toString()));
    }

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      type: _taskTypeFromString(json['type'] as String),
      checklistItems: checklist,
      reminderTime: reminder,
      repeatInterval: repeat,
      isImportant: json['isImportant'] == true,
      isDone: json['isDone'] == true,
    );
  }

  static String _taskTypeToString(TaskType t) {
    switch (t) {
      case TaskType.reminder:
        return 'reminder';
      case TaskType.habit:
        return 'habit';
      case TaskType.checklist:
        return 'checklist';
    }
  }

  static TaskType _taskTypeFromString(String s) {
    switch (s) {
      case 'reminder':
        return TaskType.reminder;
      case 'habit':
        return TaskType.habit;
      case 'checklist':
        return TaskType.checklist;
      default:
        return TaskType.reminder;
    }
  }
}

class ChecklistItem {
  final String id;
  String text;
  List<ChecklistItem> subItems;
  DateTime? deadline;
  bool isChecked;

  ChecklistItem({
    required this.id,
    required this.text,
    this.subItems = const [],
    this.deadline,
    this.isChecked = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    List<ChecklistItem>? subItems,
    DateTime? deadline,
    bool? isChecked,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      subItems: subItems ?? this.subItems,
      deadline: deadline ?? this.deadline,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'subItems': subItems.map((e) => e.toJson()).toList(),
      'deadline': deadline?.toIso8601String(),
      'isChecked': isChecked,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final subRaw = json['subItems'] as List<dynamic>? ?? [];
    final sub = subRaw.map((e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String,
      subItems: sub,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      isChecked: json['isChecked'] == true,
    );
  }
}