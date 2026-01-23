import 'package:app/screens/notifications/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:app/models/deadline_task.dart';
import 'package:app/services/task_service.dart';
import 'package:app/repositories/task_repository.dart';
import 'package:app/core/theme/app_colors.dart';
import '../notifications/notification_bell.dart';
import '../task/task_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final TaskService _taskService;
  late final String _userId;

  late Future<List<Task>> _todayTasksFuture;
  late Future<int> _weeklyTasksFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    _userId = user.uid;
    _taskService = TaskService(TaskRepository());

    _loadTasks();
  }

  void _loadTasks() {
    _todayTasksFuture = _taskService.getTodayTasks(_userId);
    _weeklyTasksFuture = _taskService.getWeeklyTasks(_userId);
    if (mounted) setState(() {});
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
      future: Future.wait<dynamic>([_todayTasksFuture, _weeklyTasksFuture]),
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return Scaffold(
          backgroundColor: AppColors.background,

          // ✅ AppBar chữ đen + chuông
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            titleSpacing: 20,
            title: const Text(
              'Timely',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary, // đen
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: NotificationBell(
                  userId: _userId,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationScreen(userId: _userId),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          body: SafeArea(
            top: false,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(snapshot),
          ),
        );
      },
    );
  }

  Widget _buildBody(AsyncSnapshot<List<dynamic>> snapshot) {
    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Đã xảy ra lỗi: ${snapshot.error}',
          style: const TextStyle(color: AppColors.textGrey),
          textAlign: TextAlign.center,
        ),
      );
    }

    final todayTasks = (snapshot.data?[0] as List<Task>?) ?? <Task>[];
    final weeklyTaskCount = (snapshot.data?[1] as int?) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= SUMMARY =================
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

        // ================= LIST =================
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
              final task = todayTasks[index];

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailScreen(
                        task: task,
                        docId: task.id!, // ⚠️ task.id phải có
                        taskService: _taskService,
                        userId: _userId,
                      ),
                    ),
                  ).then((_) => _loadTasks()); // quay về refresh
                },
                child: _TaskCard(task: task),
              );
            },
          ),
        ),
      ],
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(task.progress),
                        ),
                        backgroundColor: AppColors.progressBg,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${task.progress}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
