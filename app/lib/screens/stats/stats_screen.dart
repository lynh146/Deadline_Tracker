import 'package:app/screens/notifications/notification_bell.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/deadline_task.dart';
import '../../services/task_service.dart';
import 'status_list_screen.dart';
import '../task/task_detail_screen.dart';
import '../notifications/notification_screen.dart';

class StatsScreen extends StatefulWidget {
  final TaskService taskService;
  final String userId;

  const StatsScreen({
    super.key,
    required this.taskService,
    required this.userId,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Trạng thái",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: const BackButton(color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: NotificationBell(
              userId: widget.userId,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationScreen(userId: widget.userId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. GRID 4 Ô TRẠNG THÁI ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildStatusBox(
                  title: "Đã hoàn thành",
                  future: widget.taskService.getTasksByStatus(
                    widget.userId,
                    TaskStatus.completed,
                  ),
                  iconColor: AppColors.success,
                  icon: Icons.check_circle,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusListScreen(
                          title: "Đã hoàn thành",
                          status: TaskStatus.completed,
                          type: StatusListType.status,
                          taskService: widget.taskService,
                          userId: widget.userId,
                        ),
                      ),
                    ).then((_) => _refresh());
                  },
                ),
                _buildStatusBox(
                  title: "Đang làm",
                  future: widget.taskService.getTasksByStatus(
                    widget.userId,
                    TaskStatus.inProgress,
                  ),
                  iconColor: Colors.amber,
                  icon: Icons.hourglass_top,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusListScreen(
                          title: "Đang làm",
                          status: TaskStatus.inProgress,
                          type: StatusListType.status,
                          taskService: widget.taskService,
                          userId: widget.userId,
                        ),
                      ),
                    ).then((_) => _refresh());
                  },
                ),
                _buildStatusBox(
                  title: "Chưa làm",
                  future: widget.taskService.getNotStartedTasks(widget.userId),
                  iconColor: Colors.yellow,
                  icon: Icons.warning_amber_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusListScreen(
                          title: "Chưa làm",
                          type: StatusListType.notStarted,
                          taskService: widget.taskService,
                          userId: widget.userId,
                        ),
                      ),
                    ).then((_) => _refresh());
                  },
                ),
                _buildStatusBox(
                  title: "Hết hạn",
                  future: widget.taskService.getTasksByStatus(
                    widget.userId,
                    TaskStatus.overdue,
                  ),
                  iconColor: AppColors.danger,
                  icon: Icons.cancel,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusListScreen(
                          title: "Hết hạn",
                          status: TaskStatus.overdue,
                          type: StatusListType.status,
                          taskService: widget.taskService,
                          userId: widget.userId,
                        ),
                      ),
                    ).then((_) => _refresh());
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 2. KHUNG "SẮP HẾT HẠN" ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.detailCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning, color: Colors.amber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Sắp hết hạn",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StatusListScreen(
                                title: "Sắp hết hạn",
                                type: StatusListType.dueSoon,
                                taskService: widget.taskService,
                                userId: widget.userId,
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
                        child: const Text(
                          "Xem tất cả",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  FutureBuilder<List<Task>>(
                    future: widget.taskService.getDueSoonLatest(
                      widget.userId,
                      limit: 2,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            "Không có việc sắp hết hạn.",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!
                            .map((t) => _buildDueSoonRow(t))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. TIẾN ĐỘ CÔNG VIỆC ---
            const Text(
              "Tiến độ công việc",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            FutureBuilder<List<Task>>(
              future: widget.taskService.getInProgressSorted(widget.userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("Chưa có công việc nào.");
                }

                return Column(
                  children: snapshot.data!
                      .map(
                        (task) => TaskItemCard(
                          task: task,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskDetailScreen(
                                  task: task,
                                  docId: task.id!,
                                  taskService: widget.taskService,
                                  userId: widget.userId,
                                ),
                              ),
                            ).then((_) => _refresh());
                          },
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox({
    required String title,
    required Future<List<Task>> future,
    required Color iconColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<List<Task>>(
      future: future,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? "${snapshot.data!.length}" : "0";

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDueSoonRow(Task t) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(
              task: t,
              docId: t.id!,
              taskService: widget.taskService,
              userId: widget.userId,
            ),
          ),
        ).then((_) => _refresh());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "Đến hạn: ${t.dueAt.day}/${t.dueAt.month}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Text(
              "Sắp hết hạn",
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// CLASS TaskItemCard (Nhúng trực tiếp)
// ==========================================
class TaskItemCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const TaskItemCard({super.key, required this.task, required this.onTap});

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
                // Bỏ const để tránh lỗi constant value
                if (task.isCompleted)
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                if (task.isOverdue)
                  Icon(Icons.cancel, color: AppColors.danger, size: 20),
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
