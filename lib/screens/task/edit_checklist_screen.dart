import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class EditChecklistScreen extends StatefulWidget {
  static const routeName = '/edit_checklist';

  const EditChecklistScreen({super.key});

  @override
  State<EditChecklistScreen> createState() => _EditChecklistScreenState();
}

class _EditChecklistScreenState extends State<EditChecklistScreen> {
  late Task _task;
  late List<ChecklistItem> _items;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _task = ModalRoute.of(context)!.settings.arguments as Task;
    _items = _deepCopyItems(_task.checklistItems ?? []);
  }

  List<ChecklistItem> _deepCopyItems(List<ChecklistItem> items) {
    return items
        .map((i) => ChecklistItem(
              id: i.id,
              text: i.text,
              isChecked: i.isChecked,
              deadline: i.deadline,
              subItems: _deepCopyItems(i.subItems),
            ))
        .toList();
  }

  void _save() {
    final allChecked = _allItemsChecked(_items);
    final newTask = _task.copyWith(
      checklistItems: _deepCopyItems(_items),
      isDone: allChecked,
    );
    Provider.of<TaskService>(context, listen: false).updateTask(newTask);
    Navigator.pop(context);
  }

  bool _allItemsChecked(List<ChecklistItem> items) {
    for (final item in items) {
      if (!item.isChecked) return false;
      if (item.subItems.isNotEmpty && !_allItemsChecked(item.subItems)) {
        return false;
      }
    }
    return true;
  }

  Widget _buildChecklistEditor(
    List<ChecklistItem> items, {
    ChecklistItem? parent,
    int? parentIndex,
  }) {
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
                    Checkbox(
                      value: item.isChecked,
                      onChanged: (val) {
                        setState(() {
                          item.isChecked = val ?? false;
                        });
                      },
                    ),
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

  void _addTopLevelItem() {
    setState(() {
      _items.add(ChecklistItem(
        id: UniqueKey().toString(),
        text: '',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редагувати список'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Зберегти',
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        'Немає пунктів у цьому списку',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : SingleChildScrollView(child: _buildChecklistEditor(_items)),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Додати пункт"),
                onPressed: _addTopLevelItem,
              ),
            ),
          ],
        ),
      ),
    );
  }
}