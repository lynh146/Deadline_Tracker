import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/task.dart';
import '../../services/task_service.dart';
import '../task/task_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<Task> _tasksOfDay = [];

  // Events for marking days with tasks
  final Map<DateTime, List<Task>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadAllTasks();
    _loadTasksForDay(_selectedDay);
  }

  // Load ALL tasks to mark days with deadline
  Future<void> _loadAllTasks() async {
    final tasks = await TaskService.getAllTasks();
    _events.clear();

    for (final task in tasks) {
      final dayKey = DateTime(
        task.startAt.year,
        task.startAt.month,
        task.startAt.day,
      );

      _events.putIfAbsent(dayKey, () => []);
      _events[dayKey]!.add(task);
    }

    if (mounted) {
      setState(() {});
    }
  }

  // Load tasks of selected day
  Future<void> _loadTasksForDay(DateTime day) async {
    final tasks = await TaskService.getTasksByDate(day);

    if (mounted) {
      setState(() {
        _tasksOfDay = tasks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // CALENDAR (MONTH VIEW)
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

            // MARK DAYS WITH TASKS
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return _events[key] ?? [];
            },

            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _loadTasksForDay(selectedDay);
            },
          ),

          const SizedBox(height: 12),

          // TASK LIST OF DAY
          Expanded(
            child: _tasksOfDay.isEmpty
                ? const Center(child: Text('Không có task'))
                : ListView.builder(
                    itemCount: _tasksOfDay.length,
                    itemBuilder: (context, index) {
                      final task = _tasksOfDay[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TaskDetailScreen(taskId: task.id!),
                              ),
                            );
                          },

                          title: Text(task.title),
                          subtitle: Text(
                            'Due: ${task.dueAt.toString().substring(0, 16)}',
                          ),
                          leading: Icon(
                            Icons.circle,
                            size: 12,
                            color: task.priority == 1
                                ? Colors.red
                                : task.priority == 2
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
