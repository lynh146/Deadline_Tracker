import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/deadline_task.dart';
import 'package:app/repositories/task_repository.dart';
import 'package:app/services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../notifications/notification_bell.dart';
import '../notifications/notification_screen.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taskService = TaskService(TaskRepository());

  double _progress = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _remind1Day = false;
  bool _remind3Days = false;
  bool _remind5Days = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày bắt đầu và kết thúc')),
      );
      return;
    }

    final remindAts = <DateTime>[];
    if (_remind1Day) remindAts.add(_endDate!.subtract(const Duration(days: 1)));
    if (_remind3Days)
      remindAts.add(_endDate!.subtract(const Duration(days: 3)));
    if (_remind5Days)
      remindAts.add(_endDate!.subtract(const Duration(days: 5)));

    try {
      final task = Task(
        id: null,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startAt: _startDate!,
        dueAt: _endDate!,
        progress: _progress.round(),
        remindAt: remindAts,
      );

      await _taskService.createTask(userId: user.uid, task: task);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo công việc thành công!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tạo công việc: $e')));
    }
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final initialTime = TimeOfDay.fromDateTime(initialDate ?? DateTime.now());
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime == null) return;

    setState(() {
      final selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (isStartDate) {
        _startDate = selectedDateTime;
      } else {
        _endDate = selectedDateTime;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // ✅ Task "preview" để lấy progressColor theo logic deadline_task.dart
    // Không lưu DB, không schedule, không analytics => không ảnh hưởng tạo task
    final previewTask = Task(
      id: null,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startAt: _startDate ?? DateTime.now(),
      dueAt: _endDate ?? DateTime.now().add(const Duration(days: 1)),
      progress: _progress.round(),
      remindAt: const [],
    );

    final Color progressColor = previewTask.progressColor;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Tạo công việc',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            NotificationBell(
              userId: userId,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationScreen(userId: userId),
                  ),
                );
              },
            ),
          ],
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildTextFormField(
                            label: 'Tên công việc',
                            hint: 'Nhập tên công việc...',
                            controller: _titleController,
                          ),
                          const SizedBox(height: 16),
                          _buildTextFormField(
                            label: 'Mô tả',
                            hint: 'Mô tả chi tiết...',
                            maxLines: 4,
                            controller: _descriptionController,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateTimePicker(
                                  label: 'Ngày bắt đầu',
                                  isStart: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateTimePicker(
                                  label: 'Ngày kết thúc',
                                  isStart: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          const Text(
                            'Tiến độ ban đầu',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          // ✅ Slider đổi màu theo progressColor trong deadline_task.dart
                          Row(
                            children: [
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: progressColor,
                                    thumbColor: progressColor,
                                    overlayColor: progressColor.withOpacity(
                                      0.15,
                                    ),
                                    inactiveTrackColor: AppColors.progressBg,
                                  ),
                                  child: Slider(
                                    value: _progress,
                                    min: 0,
                                    max: 100,
                                    divisions: 100,
                                    label: '${_progress.round()}%',
                                    onChanged: (double value) {
                                      setState(() => _progress = value);
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                '${_progress.round()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const Text(
                            'Nhắc nhở',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _buildReminderCheckbox(
                            title: 'Trước 1 ngày',
                            value: _remind1Day,
                            onChanged: (val) =>
                                setState(() => _remind1Day = val ?? false),
                          ),
                          _buildReminderCheckbox(
                            title: 'Trước 3 ngày',
                            value: _remind3Days,
                            onChanged: (val) =>
                                setState(() => _remind3Days = val ?? false),
                          ),
                          _buildReminderCheckbox(
                            title: 'Trước 5 ngày',
                            value: _remind5Days,
                            onChanged: (val) =>
                                setState(() => _remind5Days = val ?? false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Center(
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Lưu',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTextFormField({
    required String label,
    required String hint,
    int maxLines = 1,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorStyle: const TextStyle(color: Colors.redAccent),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập $label';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({required String label, required bool isStart}) {
    final date = isStart ? _startDate : _endDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateTime(context, isStart),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                date != null
                    ? '${date.day}/${date.month}/${date.year} '
                    '${date.hour.toString().padLeft(2, '0')}:'
                    '${date.minute.toString().padLeft(2, '0')}'
                    : 'Chọn ngày & giờ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: date != null ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
