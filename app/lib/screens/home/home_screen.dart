import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:app/models/deadline_task.dart';
import 'package:app/services/task_service.dart';
import 'package:app/repositories/task_repository.dart';
import 'package:app/core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late TaskService _taskService;
  Future<List<Task>>? _todayTasksFuture;
  Future<int>? _weeklyTasksFuture;
  late String _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    _userId = user.uid;
    final repo = TaskRepository();
    _taskService = TaskService(repo);
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _todayTasksFuture = _taskService.getTodayTasks(_userId);
      _weeklyTasksFuture = _taskService.getWeeklyTasks(_userId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_todayTasksFuture!, _weeklyTasksFuture!]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Đã xảy ra lỗi: ${snapshot.error}',
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ),
          );
        }

        final todayTasks = (snapshot.data![0] as List<Task>?) ?? [];
        final weeklyTaskCount = (snapshot.data![1] as int?) ?? 0;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// ================= HEADER =================
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Timely',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Icon(
                        Icons.notifications_none,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),

                /// ================= SUMMARY =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.statCard,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          value: todayTasks.length,
                          label: 'Công việc\nhôm nay',
                        ),
                        _SummaryItem(
                          value: weeklyTaskCount,
                          label: 'Công việc\ntrong tuần',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Công việc hôm nay',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                /// ================= LIST TASK =================
                Expanded(
                  child: todayTasks.isEmpty
                      ? const Center(
                    child: Text(
                      'Không có công việc nào cho hôm nay!',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: todayTasks.length,
                    itemBuilder: (context, index) {
                      return _TaskCard(task: todayTasks[index]);
                    },
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

/// ================= SUMMARY ITEM =================
class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.textOnPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textOnPurple.withOpacity(0.7)),
        ),
      ],
    );
  }
}

/// ================= TASK CARD =================
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final Task task;

  String _getTimeRemaining(DateTime dueAt) {
    final diff = dueAt.difference(DateTime.now());

    if (diff.isNegative) return 'Đã quá hạn';
    if (diff.inDays > 0) return 'Còn ${diff.inDays} ngày';
    if (diff.inHours > 0) return 'Còn ${diff.inHours} giờ';
    if (diff.inMinutes > 0) return 'Còn ${diff.inMinutes} phút';
    return 'Sắp hết hạn';
  }

  Color _getProgressColor(int progress) {
    if (progress < 30) return AppColors.progressLow;
    if (progress < 80) return AppColors.progressMedium;
    return AppColors.progressHigh;
  }

  @override
  Widget build(BuildContext context) {
    final progressValue = task.progress / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              task.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 80, // Fixed width for the progress bar
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor(task.progress)),
                        backgroundColor: AppColors.progressBg,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${task.progress}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _getTimeRemaining(task.dueAt),
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
