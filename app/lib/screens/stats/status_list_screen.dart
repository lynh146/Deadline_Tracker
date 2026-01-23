import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/deadline_task.dart';
import '../../services/task_service.dart';
import '../task/task_detail_screen.dart';

class StatusListScreen extends StatefulWidget {
  final String title;
  final TaskStatus status;
  final TaskService taskService;
  final String userId;

  const StatusListScreen({
    Key? key,
    required this.title,
    required this.status,
    required this.taskService,
    required this.userId,
  }) : super(key: key);

  @override
  State<StatusListScreen> createState() => _StatusListScreenState();
}

class _StatusListScreenState extends State<StatusListScreen> {
  int _tab = 2; // Mặc định tab "Tất cả"

  @override
  Widget build(BuildContext context) {
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
              children: ["Tuần này", "Tháng này", "Tất cả"]
                  .asMap()
                  .entries
                  .map(
                    (e) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _tab == e.key
                                ? AppColors.surface
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontWeight: _tab == e.key
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

          // 2. LIST VIEW
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: widget.taskService.getTasksByStatus(
                widget.userId,
                widget.status,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Không có công việc nào."));
                }

                // Logic Lọc (Filter) bằng tay, không cần thư viện
                List<Task> tasks = snapshot.data!;
                final now = DateTime.now();

                if (_tab == 0) {
                  // Tuần này: +/- 7 ngày
                  tasks = tasks
                      .where((t) => t.dueAt.difference(now).inDays.abs() < 7)
                      .toList();
                } else if (_tab == 1) {
                  // Tháng này: so sánh tháng và năm
                  tasks = tasks
                      .where(
                        (t) =>
                            t.dueAt.month == now.month &&
                            t.dueAt.year == now.year,
                      )
                      .toList();
                }

                if (tasks.isEmpty)
                  return const Center(child: Text("Không có kết quả lọc."));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (_, i) => TaskItemCard(
                    task: tasks[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(
                          task: tasks[i],
                          docId: tasks[i].id.toString(),
                          taskService: widget.taskService,
                          userId: widget.userId,
                        ),
                      ),
                    ).then((_) => setState(() {})),
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

// ==========================================
// CLASS TaskItemCard (COPY Y HỆT BÊN TRÊN)
// ==========================================
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
