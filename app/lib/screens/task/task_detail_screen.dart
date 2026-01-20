import 'package:app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

import '../../models/deadline_task.dart';
import '../../services/task_service.dart';
import '../../repositories/task_repository.dart';
import 'task_update_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Chi tiết công việc"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== TITLE =====
            Text(
              task.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // ===== DESCRIPTION =====
            Text(task.description, style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 16),

            // ===== DEADLINE =====
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Deadline: ${_formatDate(task.dueAt)}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ===== REMINDER =====
            if (task.remindAt.isNotEmpty)
              Row(
                children: const [
                  Icon(Icons.notifications_active, size: 16),
                  SizedBox(width: 6),
                  Text("Có nhắc nhở"),
                ],
              ),

            const SizedBox(height: 24),

            // ===== PROGRESS =====
            LinearProgressIndicator(
              value: task.progress / 100,
              minHeight: 8,
              color: _progressColor(task.progress),
              backgroundColor: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text("${task.progress}% hoàn thành"),

            const Spacer(),

            // ===== ACTION BUTTONS =====
            Row(
              children: [
                // UPDATE
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskUpdateScreen(task: task),
                        ),
                      );

                      if (updated != null && context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(task: updated),
                          ),
                        );
                      }
                    },
                    child: const Text("CẬP NHẬT"),
                  ),
                ),
                const SizedBox(width: 12),

                // DELETE (CONFIRM)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Xác nhận xoá"),
                          content: const Text(
                            "Bạn có chắc chắn muốn xoá công việc này không?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("HỦY"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "XOÁ",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      await TaskService(
                        TaskRepository(),
                      ).deleteTask(task.id.toString(), task);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đã xóa công việc")),
                        );
                        Navigator.popUntil(context, (route) => route.isFirst);
                      }
                    },
                    child: const Text(
                      "XÓA",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===== FORMAT DATE =====
String _formatDate(DateTime date) {
  return "${date.day}/${date.month}/${date.year}";
}

// ===== PROGRESS COLOR =====
Color _progressColor(int progress) {
  if (progress >= 80) return AppColors.progressHigh;
  if (progress >= 30) return AppColors.progressMedium;
  return AppColors.progressLow;
}
