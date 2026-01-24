import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../models/deadline_task.dart';
import '../../services/task_service.dart';

class TaskUpdateScreen extends StatefulWidget {
  final Task task;
  final String docId;
  final TaskService taskService;
  final String userId;

  const TaskUpdateScreen({
    Key? key,
    required this.task,
    required this.docId,
    required this.taskService,
    required this.userId,
  }) : super(key: key);

  @override
  State<TaskUpdateScreen> createState() => _TaskUpdateScreenState();
}

class _TaskUpdateScreenState extends State<TaskUpdateScreen> {
  late double _currentProgress;
  late TextEditingController _descController;
  int _reminderOption = 1;

  @override
  void initState() {
    super.initState();

    _currentProgress = widget.task.progress.toDouble();
    _descController = TextEditingController(text: widget.task.description);

    if (widget.task.remindAt.isNotEmpty) {
      final diff = widget.task.dueAt
          .difference(widget.task.remindAt.first)
          .inDays;
      if (diff == 1 || diff == 3 || diff == 5) {
        _reminderOption = diff;
      } else {
        _reminderOption = 1;
      }
    } else {
      _reminderOption = 1;
    }
  }

  Color get _sliderColor {
    if (_currentProgress >= 100) return AppColors.progressHigh;
    if (_currentProgress < 30) return AppColors.progressLow;
    return AppColors.progressMedium;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Cập nhật",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.task.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _dateCol("Bắt đầu", widget.task.startAt),
                  _dateCol("Kết thúc", widget.task.dueAt),
                ],
              ),
              const SizedBox(height: 25),

              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
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
                          "${_currentProgress.toInt()}%",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10,
                        ),
                      ),
                      child: Slider(
                        value: _currentProgress,
                        min: 0,
                        max: 100,
                        activeColor: _sliderColor,
                        inactiveColor: Colors.grey[300],
                        onChanged: (val) =>
                            setState(() => _currentProgress = val),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Mô tả",
                  hintText: "Nhập mô tả...",
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "Nhắc nhớ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildRadioOption(1, "Trước 1 ngày"),
              _buildRadioOption(3, "Trước 3 ngày"),
              _buildRadioOption(5, "Trước 5 ngày"),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    "Lưu",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption(int value, String label) {
    return GestureDetector(
      onTap: () => setState(() => _reminderOption = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(
              _reminderOption == value
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: _reminderOption == value
                  ? AppColors.primary
                  : Colors.grey[300],
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _dateCol(String label, DateTime d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          DateFormat('dd/MM/yyyy').format(d),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _onSave() async {
    final updatedTask = Task(
      id: widget.task.id,
      title: widget.task.title,
      description: _descController.text,
      startAt: widget.task.startAt,
      dueAt: widget.task.dueAt,
      remindAt: [widget.task.dueAt.subtract(Duration(days: _reminderOption))],
      progress: _currentProgress.toInt(),
    );

    try {
      await widget.taskService.updateTask(
        userId: widget.userId,
        docId: widget.docId,
        task: updatedTask,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }
}
