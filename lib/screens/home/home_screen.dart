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

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final taskService = Provider.of<TaskService>(context);
    final tasksForToday = taskService.getTasksForDay(today);

    // Upcoming reminders: reminders scheduled after today within next 7 days
    final upcomingWindowEnd = DateTime.now().add(const Duration(days: 7));
    final upcomingReminders = taskService.tasks.where((t) {
      if (t.type != TaskType.reminder) return false;
      final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
      final nowDate = DateTime.now();
      return taskDate.isAfter(nowDate) && !taskDate.isAfter(upcomingWindowEnd);
    }).toList();

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
                // Load events for the day using TaskService.getTasksForDay
                eventLoader: (day) {
                  // normalize to date without time
                  final d = DateTime(day.year, day.month, day.day);
                  return taskService.getTasksForDay(d);
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    // events is a List of Task for this day (from eventLoader)
                    if (events.isEmpty) return const SizedBox.shrink();

                    // show up to 3 small dots (or 1) for presence of tasks.
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

          // Tasks for today
          Expanded(
            child: tasksForToday.isEmpty
                ? Center(
              child: Text(
                "Немає завдань на сьогодні",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: tasksForToday.length,
              itemBuilder: (_, i) {
                final task = tasksForToday[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                  child: Card(
                    elevation: 3,
                    color: task.isImportant ? Colors.orange[200] : Theme.of(context).cardColor,
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
                      subtitle: Text(
                        task.description,
                        style: const TextStyle(fontSize: 15),
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
              },
            ),
          ),

          // If there are upcoming reminders in next 7 days - show them in a separate small section
          if (upcomingReminders.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Майбутні нагадування (7 днів)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final r = upcomingReminders[i];
                        return GestureDetector(
                          onTap: () {
                            // open day view for reminder's day
                            _openDayView(r.date);
                          },
                          child: Card(
                            child: Container(
                              width: 220,
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('${r.date.day}.${r.date.month}.${r.date.year} ${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}'),
                                  const SizedBox(height: 6),
                                  Text(r.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: upcomingReminders.length,
                    ),
                  ),
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