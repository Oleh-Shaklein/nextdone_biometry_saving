import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';

class CreateReminderScreen extends StatefulWidget {
  static const routeName = '/create_reminder';
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _reminderDateTime;

  void _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // allow past if needed
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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

  void _submit() async {
    if (_titleController.text.isEmpty || _reminderDateTime == null) return;

    final newTask = Task(
      id: UniqueKey().toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      date: _reminderDateTime!,
      type: TaskType.reminder,
    );

    await Provider.of<TaskService>(context, listen: false).addTask(newTask);

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Створення ремайндера')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Новий ремайндер',
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
                label: const Text('Затвердити'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}