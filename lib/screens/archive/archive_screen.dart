import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';

class ArchiveScreen extends StatelessWidget {
  static const routeName = '/archive';

  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Архів')),
      body: Consumer<TaskService>(
        builder: (context, taskService, _) {
          final archived = taskService.archivedTasks;
          if (archived.isEmpty) {
            return const Center(child: Text('Архів порожній', style: TextStyle(fontSize: 18)));
          }
          return ListView.builder(
            itemCount: archived.length,
            itemBuilder: (_, i) {
              final task = archived[i];
              return Card(
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.unarchive, color: Colors.blueAccent),
                        tooltip: "Розархівувати",
                        onPressed: () {
                          Provider.of<TaskService>(context, listen: false).unarchiveTask(task.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                        tooltip: "Видалити з архіву",
                        onPressed: () {
                          Provider.of<TaskService>(context, listen: false).deleteArchivedTask(task.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () => Navigator.pushNamed(context, '/task_details', arguments: task),
                ),
              );
            },
          );
        },
      ),
    );
  }
}