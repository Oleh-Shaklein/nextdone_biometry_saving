import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';

class CreateChecklistScreen extends StatefulWidget {
  static const routeName = '/create_checklist';
  const CreateChecklistScreen({super.key});

  @override
  State<CreateChecklistScreen> createState() => _CreateChecklistScreenState();
}

class _CreateChecklistScreenState extends State<CreateChecklistScreen> {
  final _titleController = TextEditingController();
  final List<ChecklistItem> _items = [];

  void _addItem() {
    setState(() {
      _items.add(ChecklistItem(
        id: UniqueKey().toString(),
        text: '',
      ));
    });
  }

  /// Рекурсивно перевіряє чи всі пункти (включно з підпунктами) мають текст
  bool _areAllItemsValid(List<ChecklistItem> items) {
    for (final item in items) {
      if (item.text.trim().isEmpty) return false;
      if (item.subItems.isNotEmpty && !_areAllItemsValid(item.subItems)) {
        return false;
      }
    }
    return true;
  }

  // Рекурсивна логіка побудови редактора чеклістів
  Widget _buildChecklistEditor(List<ChecklistItem> items, {ChecklistItem? parent, int? parentIndex}) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: item.text,
                        decoration: InputDecoration(
                          labelText: parent == null ? 'Пункт' : 'Підпункт',
                        ),
                        onChanged: (val) {
                          setState(() {
                            item.text = val;
                          });
                        },
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == 'sub') {
                          setState(() {
                            item.subItems = [
                              ...item.subItems,
                              ChecklistItem(id: UniqueKey().toString(), text: ''),
                            ];
                          });
                        } else if (value == 'deadline') {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              item.deadline = picked;
                            });
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'sub',
                          child: Text('Додати підпункт'),
                        ),
                        const PopupMenuItem(
                          value: 'deadline',
                          child: Text('Дедлайн для цього'),
                        ),
                      ],
                    ),
                  ],
                ),
                if (item.deadline != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Дедлайн: ${item.deadline!.day}.${item.deadline!.month}.${item.deadline!.year}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                if (item.subItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 6),
                    child: _buildChecklistEditor(item.subItems, parent: item, parentIndex: idx),
                  ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Видалити',
                    onPressed: () {
                      setState(() {
                        if (parent != null && parentIndex != null) {
                          parent.subItems.removeAt(idx);
                        } else {
                          _items.removeAt(idx);
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _saveChecklist() async {
    // Валідація: перевіряємо що є назва та всі пункти заповнені
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Будь ласка, введіть назву списку')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Додайте хоча б один пункт до списку')),
      );
      return;
    }

    // Перевіряємо що всі пункти (включно з підпунктами) мають текст
    if (!_areAllItemsValid(_items)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заповніть всі пункти та підпункти')),
      );
      return;
    }

    final now = DateTime.now();
    final newTask = Task(
      id: UniqueKey().toString(),
      title: _titleController.text.trim(),
      description: '',
      date: now,
      type: TaskType.checklist,
      checklistItems: List<ChecklistItem>.from(_items),
    );

    await Provider.of<TaskService>(context, listen: false).addTask(newTask);

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Створення списку')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Назва списку',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                child: Text(
                  'Додайте пункти до вашого списку',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              )
                  : SingleChildScrollView(
                child: _buildChecklistEditor(_items),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Додати пункт'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _saveChecklist,
                  icon: const Icon(Icons.save),
                  label: const Text('Зберегти'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}