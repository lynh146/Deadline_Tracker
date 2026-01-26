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

class _HomeScreenState extends State<HomeScreen> {
  late final TaskService _taskService;
  late final String _userId;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    _userId = user.uid;
    _taskService = TaskService(TaskRepository());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
            color: AppColors.textPrimary,
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
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<List<Task>>(
      stream: _taskService.watchTodayTasks(_userId),
      builder: (context, todaySnap) {
        if (todaySnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (todaySnap.hasError) {
          return Center(
            child: Text(
              'Đã xảy ra lỗi: ${todaySnap.error}',
              style: const TextStyle(color: AppColors.textGrey),
              textAlign: TextAlign.center,
            ),
          );
        }

        final todayTasks = todaySnap.data ?? <Task>[];

        return StreamBuilder<int>(
          stream: _taskService.watchWeeklyTasksCount(_userId),
          builder: (context, weekSnap) {
            // ✅ không show loading nữa để tránh loading 2 lần
            final weeklyTaskCount = weekSnap.data ?? 0;

            if (weekSnap.hasError) {
              // vẫn cho UI chạy, chỉ báo lỗi nhẹ
              // (không return Center để khỏi mất phần hôm nay)
              // bạn muốn nghiêm ngặt thì đổi lại return Center cũng được
            }

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
                      final docId = task.id;

                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: docId == null
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(
                                task: task,
                                docId: docId,
                                taskService: _taskService,
                                userId: _userId,
                              ),
                            ),
                          );
                        },
                        child: _TaskCard(task: task),
                      );
                    },
                  ),
                ),
              ],
            );
          },
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
