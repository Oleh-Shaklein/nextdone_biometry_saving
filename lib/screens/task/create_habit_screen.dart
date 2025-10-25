import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';

class CreateHabitScreen extends StatefulWidget {
  static const routeName = '/create_habit';
  const CreateHabitScreen({super.key});

  @override
  State<CreateHabitScreen> createState() => _CreateHabitScreenState();
}

class _CreateHabitScreenState extends State<CreateHabitScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay? _reminderTime;
  Duration? _repeatInterval;

  void _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _pickRepeatInterval() async {
    final picked = await showDialog<Duration>(
      context: context,
      builder: (ctx) {
        Duration? selected;
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
              selected = val;
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
    if (_titleController.text.isEmpty || _reminderTime == null) return;

    final now = DateTime.now();
    final newTask = Task(
      id: UniqueKey().toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      date: DateTime(now.year, now.month, now.day, _reminderTime!.hour, _reminderTime!.minute),
      type: TaskType.habit,
      reminderTime: _reminderTime,
      repeatInterval: _repeatInterval,
    );

    Provider.of<TaskService>(context, listen: false).addTask(newTask);

    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Створення звички')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Нова звичка',
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
            const SizedBox(height: 16),
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
                label: const Text('Затвердити'),
              ),
            ),
          ],
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

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../models/habit_task.dart';
// import '../../services/task_service.dart';
// import '../home/home_screen.dart';

// class CreateHabitScreen extends StatefulWidget {
//   static const routeName = '/create-habit';

//   const CreateHabitScreen({super.key});

//   @override
//   State<CreateHabitScreen> createState() => _CreateHabitScreenState();
// }

// class _CreateHabitScreenState extends State<CreateHabitScreen> {
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   int _repeatDays = 1;

//   void _submit() {
//     if (_titleController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Заповніть назву')),
//       );
//       return;
//     }

//     final newTask = HabitTask(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       title: _titleController.text,
//       date: DateTime.now(),
//       description: _descriptionController.text,
//       repeatDays: _repeatDays,
//     );

//     Provider.of<TaskService>(context, listen: false).addTask(newTask);

//     Navigator.pushNamedAndRemoveUntil(
//       context,
//       HomeScreen.routeName,
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Створити звичку')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _titleController,
//               decoration: const InputDecoration(labelText: 'Назва'),
//             ),
//             TextField(
//               controller: _descriptionController,
//               decoration: const InputDecoration(labelText: 'Опис'),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 const Text('Повторювати кожні'),
//                 const SizedBox(width: 8),
//                 DropdownButton<int>(
//                   value: _repeatDays,
//                   items: List.generate(30, (i) => i + 1)
//                       .map((d) => DropdownMenuItem(
//                             value: d,
//                             child: Text('$d дн.'),
//                           ))
//                       .toList(),
//                   onChanged: (v) => setState(() => _repeatDays = v!),
//                 ),
//               ],
//             ),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: _submit,
//               child: const Text('Зберегти'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }