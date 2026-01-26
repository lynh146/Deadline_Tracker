import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
  bool _dirty = false;
  late double _currentProgress;
  late TextEditingController _descController;

  DateTime? _startDate;
  DateTime? _endDate;

  int _reminderOption = 1;

  @override
  void initState() {
    super.initState();

    _currentProgress = widget.task.progress.toDouble();
    _descController = TextEditingController(text: widget.task.description);

    _startDate = widget.task.startAt;
    _endDate = widget.task.dueAt;

    if (widget.task.remindAt.isNotEmpty) {
      final diff = widget.task.dueAt
          .difference(widget.task.remindAt.first)
          .inDays;
      if (diff == 1 || diff == 3 || diff == 5) {
        _reminderOption = diff;
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
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

  Future<void> _selectDateTime(bool isStartDate) async {
    final current = isStartDate ? _startDate : _endDate;

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
      initialDate: current ?? DateTime.now(),
      firstDate: isStartDate ? DateTime(2000) : (_startDate ?? DateTime(2000)),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(data: pickerTheme, child: child!),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final initialTime = TimeOfDay.fromDateTime(current ?? DateTime.now());
    final TimeOfDay? pickedTime = await _showCupertinoTimePicker(
      context,
      initialTime,
    );

    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStartDate) {
        _startDate = selectedDateTime;

        if (_endDate != null && _startDate!.isAfter(_endDate!)) {
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

  @override
  Widget build(BuildContext context) {
    final previewTask = Task(
      id: widget.task.id,
      title: widget.task.title,
      description: _descController.text,
      startAt: _startDate ?? widget.task.startAt,
      dueAt: _endDate ?? widget.task.dueAt,
      remindAt: widget.task.remindAt,
      progress: _currentProgress.toInt(),
    );
    final Color sliderColor = previewTask.progressColor;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final canLeave = await _confirmLeave();
        if (canLeave && mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "Cập nhật",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              final canLeave = await _confirmLeave();
              if (canLeave && mounted) Navigator.pop(context);
            },
          ),
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
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        label: "Bắt đầu",
                        date: _startDate,
                        onTap: () => _selectDateTime(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateTimePicker(
                        label: "Kết thúc",
                        date: _endDate,
                        onTap: () => _selectDateTime(false),
                      ),
                    ),
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
                          showValueIndicator: ShowValueIndicator.never,
                          trackHeight: 8,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                          ),
                          activeTrackColor: sliderColor,
                          thumbColor: sliderColor,
                          overlayColor: sliderColor.withOpacity(0.15),
                          inactiveTrackColor: Colors.grey[300],
                        ),
                        child: Slider(
                          value: _currentProgress,
                          min: 0,
                          max: 100,
                          divisions: 100,
                          onChanged: (val) => setState(() {
                            _currentProgress = val;
                            _dirty = true;
                          }),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: _descController,
                  maxLines: 2,
                  onChanged: (_) => setState(() => _dirty = true),
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
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
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
                    ? DateFormat('dd/MM/yyyy HH:mm', 'vi_VN').format(date)
                    : 'Chọn ngày & giờ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: date != null
                      ? AppColors.primary
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption(int value, String label) {
    return GestureDetector(
      onTap: () => setState(() {
        _reminderOption = value;
        _dirty = true;
      }),
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

  void _onSave() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày bắt đầu và kết thúc'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ngày kết thúc không thể trước ngày bắt đầu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updatedTask = Task(
      id: widget.task.id,
      title: widget.task.title,
      description: _descController.text,
      startAt: _startDate!,
      dueAt: _endDate!,
      remindAt: [_endDate!.subtract(Duration(days: _reminderOption))],
      progress: _currentProgress.toInt(),
    );

    try {
      await widget.taskService.updateTask(
        userId: widget.userId,
        docId: widget.docId,
        task: updatedTask,
      );
      if (mounted) {
        _dirty = false;
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }
}
