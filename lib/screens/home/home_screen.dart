import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../services/task_service.dart';
import '../../models/task.dart';
import '../calendar/day_view_screen.dart';
import '../task/create_reminder_screen.dart';
import '../task/create_checklist_screen.dart';
import '../task/create_habit_screen.dart';
import '../archive/archive_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _calendarExpanded = true;

  void _openDayView(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    Navigator.pushNamed(
      context,
      DayViewScreen.routeName,
      arguments: normalized,
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _openDayView(selectedDay);
  }

  void _showCreateTaskMenu(TaskType type) {
    switch (type) {
      case TaskType.reminder:
        Navigator.pushNamed(context, CreateReminderScreen.routeName);
        break;
      case TaskType.checklist:
        Navigator.pushNamed(context, CreateChecklistScreen.routeName);
        break;
      case TaskType.habit:
        Navigator.pushNamed(context, CreateHabitScreen.routeName);
        break;
    }
  }

  /// Групує всі активні завдання по датах з окремою групою для важливих
  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = today.add(const Duration(days: 7));

    Map<String, List<Task>> grouped = {
      'Актуальне': [], // Спеціальна група для важливих завдань
      'Сьогодні': [],
      'Завтра': [],
      'Цього тижня': [],
      'Пізніше': [],
    };

    for (var task in tasks) {
      // Якщо завдання важливе - додаємо до групи "Актуальне"
      if (task.isImportant) {
        grouped['Актуальне']!.add(task);
        continue; // Не додаємо до інших груп
      }

      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);

      if (taskDate.isAtSameMomentAs(today)) {
        grouped['Сьогодні']!.add(task);
      } else if (taskDate.isAtSameMomentAs(tomorrow)) {
        grouped['Завтра']!.add(task);
      } else if (taskDate.isAfter(tomorrow) && taskDate.isBefore(weekEnd)) {
        grouped['Цього тижня']!.add(task);
      } else if (taskDate.isAfter(weekEnd)) {
        grouped['Пізніше']!.add(task);
      }
    }

    // Сортуємо в кожній групі по даті/часу та статусу виконання
    for (var key in grouped.keys) {
      grouped[key]!.sort((a, b) {
        if (a.isDone != b.isDone) {
          return a.isDone ? 1 : -1;
        }
        return a.date.compareTo(b.date);
      });
    }

    return grouped;
  }

  Widget _buildTaskCard(Task task, TaskService taskService) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      child: Card(
        elevation: task.isImportant ? 5 : 3,
        color: task.isImportant ? Colors.orange[100] : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Icon(
            task.type == TaskType.reminder
                ? Icons.alarm
                : task.type == TaskType.habit
                ? Icons.repeat
                : Icons.check_box,
            color: task.isImportant ? Colors.orange : Theme.of(context).iconTheme.color,
            size: 32,
          ),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: task.isImportant ? FontWeight.bold : FontWeight.normal,
              decoration: task.isDone ? TextDecoration.lineThrough : null,
              fontSize: 18,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Text(
                '${task.date.day}.${task.date.month}.${task.date.year} '
                    '${task.date.hour.toString().padLeft(2, '0')}:${task.date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  task.isImportant
                      ? Icons.whatshot
                      : Icons.whatshot_outlined,
                  color: Colors.orange[700],
                  size: 28,
                ),
                tooltip: 'Важливе',
                onPressed: () {
                  taskService.toggleImportant(task.id);
                },
              ),
              IconButton(
                icon: Icon(
                  task.isDone
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: Colors.green,
                  size: 28,
                ),
                tooltip: 'Виконане',
                onPressed: () {
                  taskService.archiveTask(task.id);
                },
              ),
            ],
          ),
          onTap: () {
            Navigator.pushNamed(context, '/task_details', arguments: task);
          },
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Task> tasks, TaskService taskService) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    // Спеціальне оформлення для секції "Актуальне"
    final isImportantSection = title == 'Актуальне';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Row(
            children: [
              if (isImportantSection)
                const Icon(Icons.whatshot, color: Colors.orange, size: 24),
              if (isImportantSection)
                const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isImportantSection ? Colors.orange[800] : Colors.deepPurple,
                ),
              ),
              if (isImportantSection)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ...tasks.map((task) => _buildTaskCard(task, taskService)),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TaskService>(context);

    // Отримуємо всі активні завдання (не архівовані)
    final allActiveTasks = taskService.tasks;

    // Групуємо по датах
    final groupedTasks = _groupTasksByDate(allActiveTasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Головне меню'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'Архів',
            onPressed: () {
              Navigator.pushNamed(context, ArchiveScreen.routeName);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Налаштування',
            onPressed: () {
              Navigator.pushNamed(context, SettingsScreen.routeName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _calendarExpanded = !_calendarExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _calendarExpanded ? "Згорнути календар" : "Розгорнути календар",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Icon(_calendarExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _calendarExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: TableCalendar(
                locale: 'uk_UA',
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  leftChevronVisible: true,
                  rightChevronVisible: true,
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) {
                  final d = DateTime(day.year, day.month, day.day);
                  return taskService.getTasksForDay(d);
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return const SizedBox.shrink();

                    final int dotCount = events.length > 3 ? 3 : events.length;
                    return Positioned(
                      bottom: 6,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(dotCount, (index) {
                          final color = events[index] is Task
                              ? (events[index] as Task).type == TaskType.habit
                              ? Colors.green
                              : (events[index] as Task).type == TaskType.reminder
                              ? Colors.redAccent
                              : Colors.blueAccent
                              : Colors.grey;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          );
                        }),
                      ),
                    );
                  },
                ),
                onDaySelected: _onDaySelected,
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),

          // Єдиний великий список з усіма завданнями
          Expanded(
            child: allActiveTasks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Немає активних завдань",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView(
              children: [
                _buildSection('Актуальне', groupedTasks['Актуальне']!, taskService),
                _buildSection('Сьогодні', groupedTasks['Сьогодні']!, taskService),
                _buildSection('Завтра', groupedTasks['Завтра']!, taskService),
                _buildSection('Цього тижня', groupedTasks['Цього тижня']!, taskService),
                _buildSection('Пізніше', groupedTasks['Пізніше']!, taskService),
                const SizedBox(height: 80), // padding для bottomNavigationBar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.alarm),
                label: const Text("Ремайндер"),
                onPressed: () => _showCreateTaskMenu(TaskType.reminder),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_box),
                label: const Text("Список"),
                onPressed: () => _showCreateTaskMenu(TaskType.checklist),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.repeat),
                label: const Text("Звичка"),
                onPressed: () => _showCreateTaskMenu(TaskType.habit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}