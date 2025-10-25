import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../utils/show_done_dialog.dart';

class TaskDetailsScreen extends StatelessWidget {
  static const routeName = '/task_details';

  const TaskDetailsScreen({super.key});

  void _showDoneDialog(BuildContext context, TaskService service, Task task) {
    showDoneDialog(context, 
      () {
        Navigator.of(context).pop(); // закрити діалог
        service.archiveTask(task.id);
        Navigator.of(context).pop(); // повернутись назад після архівації
      },
      () {
        Navigator.of(context).pop(); // закрити діалог
        service.deleteTask(task.id);
        Navigator.of(context).pop(); // повернутись назад після видалення
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Task? task = ModalRoute.of(context)?.settings.arguments as Task?;
    final taskService = Provider.of<TaskService>(context);

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Деталі завдання')),
        body: const Center(
          child: Text(
            'Завдання не знайдено',
            style: TextStyle(fontSize: 22, color: Colors.red),
          ),
        ),
      );
    }

    void handleDoneOrChecklist(BuildContext context, Task task) {
      if (task.isDone || (task.type == TaskType.checklist && (task.checklistItems?.every((i) => i.isChecked) ?? false))) {
        _showDoneDialog(context, taskService, task);
      } else {
        // Якщо ще не виконано — просто позначити як виконане
        taskService.toggleDone(task.id);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Деталі: ${task.title}'),
        actions: [
          IconButton(
            icon: Icon(task.isImportant ? Icons.whatshot : Icons.whatshot_outlined, color: Colors.red),
            tooltip: 'Позначити як важливе',
            onPressed: () {
              taskService.toggleImportant(task.id);
            },
          ),
          IconButton(
            icon: Icon(task.isDone ? Icons.archive : Icons.check_circle, color: Colors.green),
            tooltip: 'Архівувати/Виконано',
            onPressed: () => handleDoneOrChecklist(context, task),
          ),
          if (task.type == TaskType.reminder)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редагувати нагадування',
              onPressed: () => Navigator.pushNamed(context, '/edit_reminder', arguments: task),
            ),
          if (task.type == TaskType.checklist)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редагувати список',
              onPressed: () => Navigator.pushNamed(context, '/edit_checklist', arguments: task),
            ),
          if (task.type == TaskType.habit)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редагувати звичку',
              onPressed: () => Navigator.pushNamed(context, '/edit_habit', arguments: task),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 18),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${task.date.day}.${task.date.month}.${task.date.year} '
                      '${task.date.hour.toString().padLeft(2, '0')}:${task.date.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Divider(height: 28),
              if (task.type == TaskType.checklist && task.checklistItems != null)
                Consumer<TaskService>(
                  builder: (context, service, _) {
                    final updatedTask = service.tasks.firstWhere(
                        (t) => t.id == task.id, orElse: () => task);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Пункти списку:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...?updatedTask.checklistItems?.map<Widget>((item) => ListTile(
                              leading: Checkbox(
                                value: item.isChecked,
                                onChanged: (val) {
                                  service.toggleChecklistItem(updatedTask.id, item.id);
                                  // перевірити, чи всі підпункти виконані
                                  final freshTask = service.tasks.firstWhere((t) => t.id == updatedTask.id, orElse: () => updatedTask);
                                  if (freshTask.checklistItems?.every((i) => i.isChecked) ?? false) {
                                    _showDoneDialog(context, service, freshTask);
                                  }
                                },
                              ),
                              title: Text(
                                item.text,
                                style: TextStyle(
                                  decoration: item.isChecked ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              subtitle: item.deadline != null
                                  ? Text(
                                      'Дедлайн: ${item.deadline!.day}.${item.deadline!.month}.${item.deadline!.year}',
                                      style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                                    )
                                  : null,
                            )),
                      ],
                    );
                  },
                ),
              if (task.type == TaskType.reminder)
                ListTile(
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Нагадування'),
                  subtitle: Text(task.description),
                ),
              if (task.type == TaskType.habit)
                ListTile(
                  leading: const Icon(Icons.loop),
                  title: const Text('Звичка'),
                  subtitle: Text(task.description),
                  trailing: task.repeatInterval != null
                      ? Text(
                          _intervalToString(task.repeatInterval!),
                          style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
                        )
                      : null,
                ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  String _intervalToString(Duration d) {
    if (d.inHours == 1) return 'Щогодини';
    if (d.inDays == 1) return 'Щодня';
    if (d.inDays == 7) return 'Щотижня';
    if (d.inDays == 30) return 'Щомісяця';
    return '${d.inDays} днів';
  }
}