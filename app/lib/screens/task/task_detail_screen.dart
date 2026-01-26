import 'package:app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/deadline_task.dart';
import '../../services/task_service.dart';
import 'task_update_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final String docId; // ID string để gọi update/delete
  final TaskService taskService;
  final String userId;

  const TaskDetailScreen({
    Key? key,
    required this.task,
    required this.docId,
    required this.taskService,
    required this.userId,
  }) : super(key: key);

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Chi tiết",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDateInfo("Bắt đầu", task.startAt),
                  _buildDateInfo("Kết thúc", task.dueAt),
                ],
              ),
              const SizedBox(height: 20),

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
                        const Text(
                          "Tiến độ hoàn thành",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "${task.progress}%",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: task.progress / 100.0,
                        backgroundColor: AppColors.progressBg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          task.progressColor,
                        ),
                        color: task.progressColor,
                        minHeight: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Mô tả:",
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description.isEmpty
                          ? "Không có mô tả"
                          : task.description,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskUpdateScreen(
                        task: task,
                        docId: widget.docId,
                        taskService: widget.taskService,
                        userId: widget.userId,
                      ),
                    ),
                  ).then((_) => Navigator.pop(context, true)); // ✅ refresh list
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.update,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "Cập nhật",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: _isDeleting ? null : () => _confirmDelete(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Xóa",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, DateTime date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd/MM/yyyy HH:mm').format(date),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    final task = widget.task;

    showDialog(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: Text("Bạn có chắc muốn xóa '${task.title}' không?"),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: _isDeleting
                ? null
                : () async {
                    setState(() => _isDeleting = true);

                    try {
                      await widget.taskService.deleteTask(
                        userId: widget.userId,
                        docId: widget.docId,
                        task: widget.task,
                      );

                      if (!mounted) return;

                      Navigator.pop(ctx); // đóng dialog
                      Navigator.pop(context, true); // ✅ về màn trước + refresh

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đã xóa công việc thành công!"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      Navigator.pop(ctx); // đóng dialog

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Xóa thất bại: $e"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      setState(() => _isDeleting = false);
                    }
                  },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
