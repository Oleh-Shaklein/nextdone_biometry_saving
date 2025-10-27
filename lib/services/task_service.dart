import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../models/task.dart';
import 'package:tasker_0001/utils/local_storage.dart';

class TaskService extends ChangeNotifier with WidgetsBindingObserver {
  final List<Task> _tasks = [];
  final List<Task> _archive = [];
  static const _storageKey = 'tasks_store_v1';

  TaskService() {
    if (kDebugMode) {
      print('[TaskService] new instance created, hash=${this.hashCode}');
    }
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (e, st) {
      if (kDebugMode) print('[TaskService] Failed to add observer: $e\n$st');
    }
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (kDebugMode) print('[TaskService] lifecycle state=$state, saving tasks...');
      _saveTasks();
    }
  }

  List<Task> get tasks => _tasks;
  List<Task> get archivedTasks => _archive;

  Future<void> loadFromStorage() async {
    final storage = LocalStorageService();
    final jsonStr = await storage.getString(_storageKey);
    if (kDebugMode) print('[TaskService] loadFromStorage jsonStr=${jsonStr == null ? "null" : "len:${jsonStr.length}"}');

    if (jsonStr == null) return;
    try {
      final Map<String, dynamic> decoded = json.decode(jsonStr) as Map<String, dynamic>;
      _tasks.clear();
      _archive.clear();

      final tasksRaw = decoded['tasks'] as List<dynamic>?;
      if (tasksRaw != null) {
        for (final item in tasksRaw) {
          _tasks.add(Task.fromJson(Map<String, dynamic>.from(item as Map)));
        }
      }

      final archiveRaw = decoded['archive'] as List<dynamic>?;
      if (archiveRaw != null) {
        for (final item in archiveRaw) {
          _archive.add(Task.fromJson(Map<String, dynamic>.from(item as Map)));
        }
      }

      if (kDebugMode) {
        print('[TaskService] loaded tasks=${_tasks.length} archive=${_archive.length}');
      }
      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) print('Failed to load tasks: $e\n$st');
    }
  }

  Future<void> _saveTasks() async {
    final storage = LocalStorageService();
    try {
      final data = {
        'tasks': _tasks.map((t) => t.toJson()).toList(),
        'archive': _archive.map((t) => t.toJson()).toList(),
      };
      final encoded = json.encode(data);
      await storage.saveString(_storageKey, encoded);
      if (kDebugMode) print('[TaskService] _saveTasks saved length=${encoded.length}');
    } catch (e, st) {
      if (kDebugMode) print('Failed to save tasks: $e\n$st');
    }
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> updateTask(Task updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> toggleImportant(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isImportant: !_tasks[index].isImportant);
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> toggleDone(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final updatedTask = _tasks[index].copyWith(isDone: !_tasks[index].isDone);
      await updateTask(updatedTask);
    }
  }

  /// recursively search checklist items and toggle the found item; returns true if toggled.
  bool _toggleChecklistItemRecursive(List<ChecklistItem> items, String itemId) {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.id == itemId) {
        items[i] = item.copyWith(isChecked: !item.isChecked, subItems: item.subItems);
        return true;
      }
      if (item.subItems.isNotEmpty) {
        final toggled = _toggleChecklistItemRecursive(item.subItems, itemId);
        if (toggled) {
          // After toggling a child, update parent done status only if needed (parent remains same structure)
          return true;
        }
      }
    }
    return false;
  }

  /// Recomputes isDone for a checklist task (if all nested items checked => done)
  bool _areAllChecklistItemsChecked(List<ChecklistItem> items) {
    for (final item in items) {
      if (!item.isChecked) return false;
      if (item.subItems.isNotEmpty && !_areAllChecklistItemsChecked(item.subItems)) {
        return false;
      }
    }
    return true;
  }

  Future<void> toggleChecklistItem(String taskId, String itemId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _tasks[index];
    if (task.checklistItems == null) return;

    // operate on a deep copy structure to avoid mutations surprises
    final clonedItems = _cloneChecklistList(task.checklistItems!);

    final toggled = _toggleChecklistItemRecursive(clonedItems, itemId);
    if (!toggled) return;

    final allChecked = _areAllChecklistItemsChecked(clonedItems);
    final updatedTask = task.copyWith(
      checklistItems: clonedItems,
      isDone: allChecked,
    );

    _tasks[index] = updatedTask;
    await _saveTasks();
    notifyListeners();
  }

  // Helper to deep clone checklist items
  List<ChecklistItem> _cloneChecklistList(List<ChecklistItem> items) {
    return items.map((i) => i.copyWith(
      subItems: _cloneChecklistList(i.subItems),
    )).toList();
  }

  Future<void> archiveTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _tasks[index].copyWith(isDone: true);
      _archive.add(task);
      _tasks.removeAt(index);
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> unarchiveTask(String id) async {
    final index = _archive.indexWhere((t) => t.id == id);
    if (index != -1) {
      final task = _archive[index].copyWith(isDone: false);
      _tasks.add(task);
      _archive.removeAt(index);
      await _saveTasks();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _saveTasks();
    notifyListeners();
  }

  Future<void> deleteArchivedTask(String id) async {
    _archive.removeWhere((t) => t.id == id);
    await _saveTasks();
    notifyListeners();
  }

  // getTasksForDay unchanged, still generates occurrences for habits
  List<Task> getTasksForDay(DateTime day) {
    final check = DateTime(day.year, day.month, day.day);

    List<Task> result = [];
    for (var task in _tasks) {
      final start = DateTime(task.date.year, task.date.month, task.date.day);

      if (task.type == TaskType.habit && task.repeatInterval != null) {
        if (task.repeatInterval == const Duration(hours: 1)) {
          if (check.isAfter(start) || check.isAtSameMomentAs(start)) {
            for (int h = 0; h < 24; h++) {
              final taskForHour = task.copyWith(
                date: DateTime(check.year, check.month, check.day, h),
              );
              result.add(taskForHour);
            }
            continue;
          }
        }
        if (task.repeatInterval == const Duration(days: 1)) {
          if (check.isAfter(start) || check.isAtSameMomentAs(start)) {
            result.add(task);
            continue;
          }
        }
        if (task.repeatInterval == const Duration(days: 7)) {
          if (check.weekday == start.weekday &&
              (check.isAfter(start) || check.isAtSameMomentAs(start))) {
            result.add(task);
            continue;
          }
        }
        if (task.repeatInterval == const Duration(days: 30)) {
          if (check.day == start.day &&
              (check.isAfter(start) || check.isAtSameMomentAs(start))) {
            result.add(task);
            continue;
          }
        }
      }

      if (task.date.year == day.year &&
          task.date.month == day.month &&
          task.date.day == day.day) {
        result.add(task);
      }
    }

    result.sort((a, b) {
      if (a.isImportant != b.isImportant) {
        return b.isImportant ? 1 : -1;
      }
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }
      return 0;
    });

    return result;
  }

  Map<DateTime, List<Task>> getTasksGroupedByDate() {
    Map<DateTime, List<Task>> grouped = {};
    for (var task in _tasks) {
      final date = DateTime(task.date.year, task.date.month, task.date.day);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(task);
    }
    return grouped;
  }

  List<Task> getTasksByType(TaskType type) {
    return _tasks.where((task) => task.type == type).toList();
  }
}