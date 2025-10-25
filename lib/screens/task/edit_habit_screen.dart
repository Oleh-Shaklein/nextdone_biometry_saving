import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class EditHabitScreen extends StatefulWidget {
  static const routeName = '/edit_habit';

  const EditHabitScreen({super.key});

  @override
  State<EditHabitScreen> createState() => _EditHabitScreenState();
}

class _EditHabitScreenState extends State<EditHabitScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  TimeOfDay? _reminderTime;
  Duration? _repeatInterval;
  late Task _task;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Task? task = ModalRoute.of(context)?.settings.arguments as Task?;
    if (task == null) {
      Navigator.pop(context);
      return;
    }
    _task = task;
    _titleController = TextEditingController(text: task.title);
    _descriptionController = TextEditingController(text: task.description);
    _reminderTime = task.reminderTime;
    _repeatInterval = task.repeatInterval;
  }

  void _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _pickRepeatInterval() async {
    final picked = await showDialog<Duration>(
      context: context,
      builder: (ctx) {
        Duration? selected = _repeatInterval;
        return AlertDialog(
          title: const Text('Виберіть періодичність'),
          content: DropdownButton<Duration>(
            value: selected,
            items: const [
              DropdownMenuItem(value: Duration(hours: 1), child: Text('Щогодини')),
              DropdownMenuItem(value: Duration(days: 1), child: Text('Щодня')),
              DropdownMenuItem(value: Duration(days: 7), child: Text('Щотижня')),
              DropdownMenuItem(value: Duration(days: 30), child: Text('Щомісяця')),
            ],
            onChanged: (val) {
              Navigator.of(ctx).pop(val);
            },
            hint: const Text('Оберіть період'),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() => _repeatInterval = picked);
    }
  }

  void _submit() {
    final now = DateTime.now();
    final updatedTask = Task(
      id: _task.id,
      title: _titleController.text,
      description: _descriptionController.text,
      date: DateTime(now.year, now.month, now.day, _reminderTime?.hour ?? 0, _reminderTime?.minute ?? 0),
      type: TaskType.habit,
      reminderTime: _reminderTime,
      repeatInterval: _repeatInterval,
      isImportant: _task.isImportant,
      isDone: _task.isDone,
    );
    Provider.of<TaskService>(context, listen: false).updateTask(updatedTask);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  String _intervalToString(Duration d) {
    if (d.inHours == 1) return 'Щогодини';
    if (d.inDays == 1) return 'Щодня';
    if (d.inDays == 7) return 'Щотижня';
    if (d.inDays == 30) return 'Щомісяця';
    return '${d.inDays} днів';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редагування звички')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Редагувати звичку',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Назва звички',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Опис/нагадування',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active),
              title: const Text('Час нагадування'),
              subtitle: Text(
                _reminderTime != null
                    ? _reminderTime!.format(context)
                    : 'Не вибрано',
              ),
              trailing: TextButton(
                onPressed: _pickReminderTime,
                child: const Text('Вибрати'),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.repeat),
              title: const Text('Періодичність нагадування'),
              subtitle: Text(
                _repeatInterval != null
                    ? _intervalToString(_repeatInterval!)
                    : 'Не вибрано',
              ),
              trailing: TextButton(
                onPressed: _pickRepeatInterval,
                child: const Text('Вибрати'),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.check),
                label: const Text('Затвердити зміни'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}