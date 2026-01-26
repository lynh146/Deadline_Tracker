import 'package:app/core/theme/app_colors.dart'; //month
import 'package:app/models/deadline_task.dart';
import '../../repositories/task_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarMonthScreen extends StatefulWidget {
  final Function(DateTime) onDaySelected;

  const CalendarMonthScreen({super.key, required this.onDaySelected});

  @override
  State<CalendarMonthScreen> createState() => _CalendarMonthScreenState();
}

class _CalendarMonthScreenState extends State<CalendarMonthScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  final _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  Map<DateTime, List<Task>> _groupByDueDay(List<Task> tasks) {
    final Map<DateTime, List<Task>> groupedTasks = {};
    for (final task in tasks) {
      final date = DateTime.utc(
        task.dueAt.year,
        task.dueAt.month,
        task.dueAt.day,
      );
      if (groupedTasks[date] == null) {
        groupedTasks[date] = [];
      }
      groupedTasks[date]!.add(task);
    }
    return groupedTasks;
  }

  List<Task> _getTasksForDay(Map<DateTime, List<Task>> grouped, DateTime day) {
    return grouped[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  Color _getIndicatorColor(int taskCount) {
    if (taskCount >= 3) {
      return Colors.red;
    } else if (taskCount == 2) {
      return AppColors.primary;
    }
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return StreamBuilder<List<Task>>(
      stream: user == null
          ? Stream.value(<Task>[])
          : _taskRepository.watchTasksByUser(user.uid), // ✅ realtime
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final tasks = snapshot.data ?? <Task>[];
        final grouped = _groupByDueDay(tasks);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildDaysOfWeekHeader(),
              TableCalendar(
                locale: 'vi_VN',
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                rowHeight: 80,
                daysOfWeekVisible: false,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  prioritizedBuilder: (context, day, focusedDay) {
                    final bool isSelected = isSameDay(_selectedDay, day);
                    final bool isOutside = day.month != focusedDay.month;

                    final tasksOnDay = _getTasksForDay(grouped, day);
                    final Color indicatorColor = _getIndicatorColor(
                      tasksOnDay.length,
                    );

                    return Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : isOutside
                                      ? Colors.grey.shade400
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (tasksOnDay.isNotEmpty && !isOutside)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: isSelected
                                      ? Colors.white
                                      : indicatorColor,
                                  child: Text(
                                    '${tasksOnDay.length}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? indicatorColor
                                          : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  widget.onDaySelected(selectedDay);
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  // ✅ realtime nên không cần _loadTasks()
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDaysOfWeekHeader() {
    const List<String> dow = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: dow
            .map(
              (day) => Text(
            day,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}
