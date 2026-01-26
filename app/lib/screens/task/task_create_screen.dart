import 'package:app/core/theme/app_colors.dart';
import 'package:app/models/deadline_task.dart';
import 'package:app/repositories/task_repository.dart';
import 'package:app/services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../notifications/notification_bell.dart';
import '../notifications/notification_screen.dart';

class TaskCreateScreen extends StatefulWidget {
  final DateTime? initialDate;

  const TaskCreateScreen({super.key, this.initialDate});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _taskService = TaskService(TaskRepository());

  bool _dirty = false;

  double _progress = 0.0;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _remind1Day = false;
  bool _remind3Days = false;
  bool _remind5Days = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _startDate = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
        9,
        0,
      );
      _endDate = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
        17,
        0,
      );
    }

    _titleController.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
    _descriptionController.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bạn chưa lưu'),
        content: const Text(
          'Thoát ra sẽ mất thay đổi. Bạn có muốn thoát không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );

    return ok == true;
  }

  Future<TimeOfDay?> _showCupertinoTimePicker(
      BuildContext context,
      TimeOfDay initial,
      ) async {
    TimeOfDay tempPicked = initial;

    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    const Text(
                      'Chọn giờ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, tempPicked),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(
                    2000,
                    1,
                    1,
                    initial.hour,
                    initial.minute,
                  ),
                  onDateTimeChanged: (dt) {
                    tempPicked = TimeOfDay(hour: dt.hour, minute: dt.minute);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartDate) async {
    final initialDate = isStartDate ? _startDate : _endDate ?? _startDate;

    final pickerTheme = Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      dialogBackgroundColor: AppColors.background,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
    );

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: isStartDate ? DateTime(2000) : _startDate ?? DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(data: pickerTheme, child: child!),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final initialTime = TimeOfDay.fromDateTime(initialDate ?? DateTime.now());
    final TimeOfDay? pickedTime = await _showCupertinoTimePicker(
      context,
      initialTime,
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
        if (_endDate != null && selectedDateTime.isAfter(_endDate!)) {
          _endDate = null;
        }
      } else {
        if (_startDate != null && selectedDateTime.isBefore(_startDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ngày kết thúc không thể trước ngày bắt đầu.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _endDate = selectedDateTime;
      }

      _dirty = true;
    });
  }

  Future<void> _saveTask() async {
    if (_isSaving) return;

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

    setState(() => _isSaving = true);

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

      _dirty = false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo công việc thành công!')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tạo công việc: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final canLeave = await _confirmLeave();
        if (canLeave && mounted) Navigator.pop(context);
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
              onPressed: () async {
                final canLeave = await _confirmLeave();
                if (canLeave && mounted) Navigator.of(context).pop();
              },
            ),
            title: const Text(
              'Tạo công việc',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: NotificationBell(
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
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                      requiredField: false,
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

                    Row(
                      children: [
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              showValueIndicator: ShowValueIndicator.never,
                              activeTrackColor: progressColor,
                              thumbColor: progressColor,
                              overlayColor: progressColor.withOpacity(0.15),
                              inactiveTrackColor: AppColors.progressBg,
                            ),
                            child: Slider(
                              value: _progress,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: '${_progress.round()}%',
                              onChanged: (double value) {
                                setState(() {
                                  _progress = value;
                                  _dirty = true;
                                });
                              },
                            ),
                          ),
                        ),
                        Text(
                          '${_progress.round()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                      onChanged: (val) => setState(() {
                        _remind1Day = val ?? false;
                        _dirty = true;
                      }),
                    ),
                    _buildReminderCheckbox(
                      title: 'Trước 3 ngày',
                      value: _remind3Days,
                      onChanged: (val) => setState(() {
                        _remind3Days = val ?? false;
                        _dirty = true;
                      }),
                    ),
                    _buildReminderCheckbox(
                      title: 'Trước 5 ngày',
                      value: _remind5Days,
                      onChanged: (val) => setState(() {
                        _remind5Days = val ?? false;
                        _dirty = true;
                      }),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
          persistentFooterButtons: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text(
                  'Lưu',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
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
    bool requiredField = true,
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
            if (!requiredField) return null;
            if (value == null || value.isEmpty) return 'Vui lòng nhập $label';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({required String label, required bool isStart}) {
    final date = isStart ? _startDate : _endDate;
    final isEnabled = isStart || _startDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: isEnabled ? () => _selectDateTime(context, isStart) : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                if (isEnabled)
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
                    ? DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(
                  date,
                ) // ✅ 24h
                    : 'Chọn ngày & giờ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: isEnabled
                      ? (date != null ? Colors.black87 : Colors.grey.shade600)
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
