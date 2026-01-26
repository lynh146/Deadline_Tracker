import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/deadline_task.dart';
import '../../services/task_service.dart';
import '../task/task_detail_screen.dart';

enum StatusListType { status, notStarted, dueSoon }

class StatusListScreen extends StatefulWidget {
  final String title;
  final TaskStatus? status;
  final StatusListType type;
  final TaskService taskService;
  final String userId;

  const StatusListScreen({
    Key? key,
    required this.title,
    required this.taskService,
    required this.userId,
    this.status,
    this.type = StatusListType.status,
  }) : super(key: key);

  @override
  State<StatusListScreen> createState() => _StatusListScreenState();
}

class _StatusListScreenState extends State<StatusListScreen> {
  int _tab = 2; // 0 tuần, 1 tháng, 2 tất cả
  int _dueSoonTab = 1; // 0:1d, 1:3d, 2:5d

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _startOfWeek(DateTime today) {
    final start = _startOfDay(today);
    return start.subtract(Duration(days: today.weekday - DateTime.monday));
  }

  List<Task> _applyWeekMonthAllFilter(List<Task> tasks) {
    final now = DateTime.now();

    if (_tab == 0) {
      final startWeek = _startOfWeek(now);
      final endWeek = startWeek.add(const Duration(days: 7));
      tasks = tasks
          .where(
            (t) => !t.dueAt.isBefore(startWeek) && t.dueAt.isBefore(endWeek),
          )
          .toList();
    } else if (_tab == 1) {
      // Tháng này
      tasks = tasks
          .where((t) => t.dueAt.month == now.month && t.dueAt.year == now.year)
          .toList();
    }

    tasks.sort((a, b) {
      final dateCompare = a.dueAt.compareTo(b.dueAt);
      if (dateCompare != 0) return dateCompare;
      return a.progress.compareTo(b.progress);
    });

    return tasks;
  }

  Stream<List<Task>> _watchTasks() {
    final base = widget.taskService.watchAllTasks(widget.userId);

    if (widget.type == StatusListType.dueSoon) {
      final days = _dueSoonTab == 0 ? 1 : (_dueSoonTab == 1 ? 3 : 5);
      return base.map(
        (tasks) => widget.taskService.filterDueSoon(tasks, days: days),
      );
    }

    if (widget.type == StatusListType.notStarted) {
      return base.map((tasks) => widget.taskService.filterNotStarted(tasks));
    }

    // status
    return base.map(
      (tasks) => widget.taskService.filterByStatus(tasks, widget.status!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDueSoon = widget.type == StatusListType.dueSoon;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // giảm flash đen
        scrolledUnderElevation: 0, // giảm flash đen (Material3)
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. THANH TAB
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children:
                  (isDueSoon
                          ? ["1 ngày", "3 ngày", "5 ngày"]
                          : ["Tuần này", "Tháng này", "Tất cả"])
                      .asMap()
                      .entries
                      .map(
                        (e) => Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              if (isDueSoon) {
                                _dueSoonTab = e.key;
                              } else {
                                _tab = e.key;
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: (isDueSoon ? _dueSoonTab : _tab) == e.key
                                    ? AppColors.surface
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontWeight:
                                      (isDueSoon ? _dueSoonTab : _tab) == e.key
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          // 2. LIST VIEW (✅ StreamBuilder)
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _watchTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Không có công việc nào."));
                }

                List<Task> tasks = snapshot.data!;

                if (!isDueSoon) {
                  tasks = _applyWeekMonthAllFilter(tasks);
                }

                if (tasks.isEmpty) {
                  return const Center(child: Text("Không có kết quả lọc."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => TaskItemCard(
                    task: tasks[i],
                    onTap: () {
                      final id = tasks[i].id;
                      if (id == null) return; // tránh crash
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailScreen(
                            task: tasks[i],
                            docId: id,
                            taskService: widget.taskService,
                            userId: widget.userId,
                          ),
                        ),
                      );
                    },
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

class TaskItemCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskItemCard({Key? key, required this.task, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    String dayStr = "${task.dueAt.day}/${task.dueAt.month}";
    String dateStr = task.isOverdue ? "Hết hạn $dayStr" : "Đến hạn: $dayStr";

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (task.isCompleted)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 20,
                  ),
                if (task.isOverdue)
                  const Icon(Icons.cancel, color: AppColors.danger, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: task.progress / 100,
                backgroundColor: AppColors.progressBg,
                valueColor: AlwaysStoppedAnimation<Color>(task.progressColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${task.progress}%",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
