import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class EditReminderScreen extends StatefulWidget {
  static const routeName = '/edit_reminder';

  const EditReminderScreen({super.key});

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _reminderDateTime;
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
    _reminderDateTime = task.date;
  }

  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _reminderDateTime != null
          ? TimeOfDay(hour: _reminderDateTime!.hour, minute: _reminderDateTime!.minute)
          : TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _reminderDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    final updatedTask = Task(
      id: _task.id,
      title: _titleController.text,
      description: _descriptionController.text,
      date: _reminderDateTime ?? DateTime.now(),
      type: TaskType.reminder,
      isImportant: _task.isImportant,
      isDone: _task.isDone,
      // checklistItems, reminderTime, repeatInterval залишаються null
    );
    Provider.of<TaskService>(context, listen: false).updateTask(updatedTask);
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редагування ремайндера')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Редагувати ремайндер',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Назва',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Текст нагадування',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time),
              title: const Text('Час нагадування'),
              subtitle: Text(
                _reminderDateTime != null
                    ? '${_reminderDateTime!.day}.${_reminderDateTime!.month}.${_reminderDateTime!.year} '
                    '${_reminderDateTime!.hour.toString().padLeft(2, '0')}:'
                    '${_reminderDateTime!.minute.toString().padLeft(2, '0')}'
                    : 'Не вибрано',
              ),
              trailing: TextButton(
                onPressed: _pickDateTime,
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