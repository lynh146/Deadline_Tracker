import 'package:flutter/material.dart';
import 'package:app/core/theme/app_colors.dart';

import '../../models/deadline_task.dart';
import '../../services/task_service.dart';
import '../../repositories/task_repository.dart';
import '../../services/notification_service.dart';

class TaskUpdateScreen extends StatefulWidget {
  final Task task;
  const TaskUpdateScreen({super.key, required this.task});

  @override
  State<TaskUpdateScreen> createState() => _TaskUpdateScreenState();
}

class _TaskUpdateScreenState extends State<TaskUpdateScreen> {
  late TextEditingController _descController;
  late DateTime _dueAt;
  late int _progress;
  late List<DateTime> _remindAt;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.task.description);
    _dueAt = widget.task.dueAt;
    _progress = widget.task.progress;
    _remindAt = List.from(widget.task.remindAt);
  }

  // ===== PICK DATE =====
  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt),
    );
    if (time == null) return;

    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // ===== SAVE =====
  Future<void> _save() async {
    final updatedTask = Task(
      id: widget.task.id,
      title: widget.task.title,
      description: _descController.text,
      startAt: widget.task.startAt,
      dueAt: _dueAt,
      remindAt: _remindAt,
      priority: widget.task.priority,
      progress: _progress,
    );

    await TaskService(
      TaskRepository(),
    ).updateTask(docId: updatedTask.id.toString(), task: updatedTask);

    // =========================
    // DAY 6: TRIGGER COMPLETE NOTIFICATION
    // =========================
    if (_progress == 100) {
      await NotificationService.instance.showComplete(
        id: updatedTask.id!,
        taskTitle: updatedTask.title,
      );
    }

    if (mounted) {
      Navigator.pop(context, updatedTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cập nhật công việc")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== DESCRIPTION =====
            const Text("Mô tả"),
            TextField(controller: _descController, maxLines: 3),

            const SizedBox(height: 16),

            // ===== DEADLINE =====
            Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  "${_dueAt.day}/${_dueAt.month}/${_dueAt.year} "
                  "${_dueAt.hour}:${_dueAt.minute.toString().padLeft(2, '0')}",
                ),
                const Spacer(),
                TextButton(onPressed: _pickDateTime, child: const Text("Đổi")),
              ],
            ),

            const SizedBox(height: 16),

            // ===== REMINDER =====
            CheckboxListTile(
              value: _remindAt.isNotEmpty,
              title: const Text("Bật nhắc nhở"),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _remindAt = [_dueAt.subtract(const Duration(minutes: 30))];
                  } else {
                    _remindAt.clear();
                  }
                });
              },
            ),

            const SizedBox(height: 16),

            // ===== PROGRESS =====
            Text("Tiến độ: $_progress%"),
            Slider(
              value: _progress.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              activeColor: _progressColor(_progress),
              onChanged: (v) {
                setState(() => _progress = v.round());
              },
            ),

            const Spacer(),

            // ===== SAVE =====
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: const Text("LƯU")),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== PROGRESS COLOR =====
Color _progressColor(int progress) {
  if (progress >= 100) return AppColors.progressHigh;
  if (progress >= 70) return AppColors.progressHigh;
  if (progress >= 30) return AppColors.progressMedium;
  return AppColors.progressLow;
}
