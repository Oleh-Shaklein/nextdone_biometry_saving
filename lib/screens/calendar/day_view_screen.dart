import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';

class DayViewScreen extends StatelessWidget {
  static const routeName = '/day_view';

  const DayViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DateTime day = ModalRoute.of(context)!.settings.arguments as DateTime;
    final tasks = Provider.of<TaskService>(context).getTasksForDay(day);
    final theme = Theme.of(context);
    
    List<Widget> hourRows = [];
    for (int hour = 0; hour < 24; hour++) {
      final hourTasks = tasks.where((task) => task.date.hour == hour).toList();
      hourRows.add(
        Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
            color: theme.brightness == Brightness.dark
                ? (hour % 2 == 0 ? Colors.grey[900] : Colors.black)
                : (hour % 2 == 0 ? Colors.grey[100] : Colors.white),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: hourTasks.isEmpty
                    ? const SizedBox()
                    : Wrap(
                        spacing: 8,
                        children: hourTasks.map((task) {
                          return Chip(
                            label: Text(
                              task.title,
                              style: TextStyle(
                                color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                            backgroundColor: task.isImportant
                                ? Colors.orange[400]
                                : (theme.brightness == Brightness.dark ? Colors.deepPurple[700] : Colors.deepPurple[100]),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${day.day}.${day.month}.${day.year} (розклад)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: hourRows,
      ),
    );
  }
}