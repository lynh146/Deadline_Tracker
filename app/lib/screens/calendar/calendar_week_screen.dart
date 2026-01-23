import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/deadline_task.dart';
import '../../repositories/task_repository.dart';
import '../task/task_create_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWeekScreen extends StatefulWidget {
  final DateTime focusedDay;
  final Function(DateTime) onDaySelected;

  const CalendarWeekScreen({
    super.key,
    required this.focusedDay,
    required this.onDaySelected,
  });

  @override
  State<CalendarWeekScreen> createState() => _CalendarWeekScreenState();
}

class _CalendarWeekScreenState extends State<CalendarWeekScreen> {
  final TaskRepository _taskRepository = TaskRepository();
  final _auth = FirebaseAuth.instance;
  late Map<DateTime, List<Task>> _tasksByDay;
  late List<Task> _selectedTasks;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.focusedDay;
    _selectedDay = _focusedDay;
    _selectedTasks = [];
    _tasksByDay = {};
    _loadAllTasksAndTasksForSelectedDay();
  }

  Future<void> _loadAllTasksAndTasksForSelectedDay() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final allTasks = await _taskRepository.getTasksByUser(user.uid);
    final Map<DateTime, List<Task>> groupedTasks = {};
    for (final task in allTasks) {
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

    if (mounted) {
      setState(() {
        _tasksByDay = groupedTasks;
        _selectedTasks = _getTasksForDay(_selectedDay!);
      });
    }
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasksByDay[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _navigateToCreateScreen() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TaskCreateScreen()));

    if (result == true) {
      _loadAllTasksAndTasksForSelectedDay();
    }
  }

  Color _getTaskProgressColor(int progress) {
    if (progress < 30) return AppColors.progressLow;
    if (progress < 80) return AppColors.progressMedium;
    return AppColors.progressHigh;
  }

  @override
  Widget build(BuildContext context) {
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
            calendarFormat: CalendarFormat.week,
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
                final tasksOnDay = _getTasksForDay(day);

                return Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.white,
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
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (tasksOnDay.isNotEmpty)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${tasksOnDay.length}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedTasks = _getTasksForDay(selectedDay);
                });
                widget.onDaySelected(selectedDay);
              }
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
          const SizedBox(height: 16.0),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: _selectedTasks.isEmpty
                  ? _buildEmptyView()
                  : _buildTaskListView(),
            ),
          ),
        ],
      ),
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

  Widget _buildEmptyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80), // Increased from 48 to push it down more
        const Text(
          'Chưa có công việc',
          style: TextStyle(fontSize: 16, color: AppColors.textGrey),
        ),
        const SizedBox(height: 24),
        FloatingActionButton(
          onPressed: _navigateToCreateScreen,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: AppColors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tạo công việc mới',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskListView() {
    return ListView.builder(
      itemCount: _selectedTasks.length,
      itemBuilder: (context, index) {
        final task = _selectedTasks[index];
        final progressValue = task.progress / 100;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${task.progress}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: AppColors.progressBg,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getTaskProgressColor(task.progress),
                    ),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
