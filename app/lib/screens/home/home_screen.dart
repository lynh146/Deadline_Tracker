import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = TaskService.getAllTasks();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: _tasksFuture,
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

        final tasks = snapshot.data ?? [];
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);

        final todayTasks = tasks.where((task) {
          if (task.dueAt == null) return false;
          return _isSameDay(task.dueAt!, now);
        }).toList()
          ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

        final weekTasks = tasks.where((task) {
          if (task.dueAt == null) return false;
          final dueDay =
          DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
          return dueDay.isAfter(startOfToday) &&
              dueDay.isBefore(startOfToday.add(const Duration(days: 7)));
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HEADER
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      Icon(Icons.notifications_none,
                          color: AppColors.textPrimary),
                    ],
                  ),
                ),

                /// SUMMARY CARD
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
                          value: weekTasks.length,
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

                /// LIST TASK
                Expanded(
                  child: todayTasks.isEmpty
                      ? const Center(
                    child: Text(
                      'Không có công việc nào cho hôm nay!',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  )
                      : ListView.builder(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20),
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
          style: TextStyle(
            color: AppColors.textOnPurple.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// ================= TASK CARD =================
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});
  final Task task;

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return AppColors.progressLow;
    if (progress < 0.7) return AppColors.progressMedium;
    return AppColors.progressHigh;
  }

  String _getTimeRemaining(DateTime? dueAt) {
    if (dueAt == null) return 'Không có hạn';
    final diff = dueAt.difference(DateTime.now());
    if (diff.isNegative) return 'Đã quá hạn';
    if (diff.inDays > 0) return 'Còn ${diff.inDays} ngày';
    if (diff.inHours > 0) return 'Còn ${diff.inHours} giờ';
    if (diff.inMinutes > 0) return 'Còn ${diff.inMinutes} phút';
    return 'Sắp hết hạn';
  }

  @override
  Widget build(BuildContext context) {
    final progress = (task.progress ?? 0.0).toDouble();
    final progressColor = _getProgressColor(progress);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title ?? 'Không có tiêu đề',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            backgroundColor: AppColors.progressBg,
          ),
          const SizedBox(height: 6),
          Text(
            _getTimeRemaining(task.dueAt),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
