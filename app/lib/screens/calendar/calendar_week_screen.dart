import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/deadline_task.dart';
import 'package:app/repositories/task_repository.dart';
import 'package:app/screens/task/task_detail_screen.dart';
import 'package:app/services/task_service.dart';
import '../task/task_create_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWeekScreen extends StatefulWidget {
  //week
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
  late final TaskService _taskService;
  final _auth = FirebaseAuth.instance;

  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _taskService = TaskService(_taskRepository);
    _focusedDay = widget.focusedDay;
    _selectedDay = _focusedDay;
  }

  // ===== REALTIME HELPERS =====
  Map<DateTime, List<Task>> _groupByDueDay(List<Task> allTasks) {
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

    // sort mỗi ngày để list ổn định (realtime đỡ nhảy)
    for (final e in groupedTasks.entries) {
      e.value.sort((a, b) {
        final c = a.dueAt.compareTo(b.dueAt);
        if (c != 0) return c;
        return a.progress.compareTo(b.progress);
      });
    }

    return groupedTasks;
  }

  List<Task> _getTasksForDay(Map<DateTime, List<Task>> grouped, DateTime day) {
    return grouped[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _navigateToCreateScreen() async {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => TaskCreateScreen(initialDate: _selectedDay),
      ),
    );
    // realtime nên không cần reload
  }

  void _navigateToDetailScreen(Task task) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docId = task.id;
    if (docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi: Không tìm thấy ID của công việc.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          task: task,
          docId: docId,
          taskService: _taskService,
          userId: user.uid,
        ),
      ),
    );
    // realtime nên không cần reload
  }

  Color _getTaskProgressColor(int progress) {
    if (progress < 30) return AppColors.progressLow;
    if (progress < 80) return AppColors.progressMedium;
    return AppColors.progressHigh;
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return StreamBuilder<List<Task>>(
      stream: user == null
          ? Stream.value(<Task>[])
          : _taskService.watchAllTasks(user.uid), // ✅ realtime
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        final allTasks = snapshot.data ?? <Task>[];
        final grouped = _groupByDueDay(allTasks);

        final selectedDay = _selectedDay ?? _focusedDay;
        final selectedTasks = _getTasksForDay(grouped, selectedDay);

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
                    final tasksOnDay = _getTasksForDay(grouped, day);

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
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
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
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: selectedTasks.isEmpty
                      ? _buildEmptyView()
                      : _buildTaskListView(selectedTasks),
                ),
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

  Widget _buildEmptyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
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
          child: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildTaskListView(List<Task> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final progressValue = task.progress / 100;

        return InkWell(
          onTap: () => _navigateToDetailScreen(task),
          child: Card(
            color: const Color(0xFFF6F1FF), // Light purple background
            elevation: 0, // No shadow
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                          color: Colors.black87,
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
          ),
        );
      },
    );
  }
}
