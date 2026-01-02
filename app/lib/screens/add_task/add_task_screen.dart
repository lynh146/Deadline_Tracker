import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime? _startAt;
  DateTime? _dueAt;

  int _priority = 1;
  double _progress = 0;

  final Map<int, bool> _remindOptions = {1: false, 3: false, 5: false};

  // DATE
  Future<DateTime?> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  //  PICK START / DUE DATE
  Future<void> _pickStartDateTime() async {
    final picked = await _pickDateTime();
    if (picked == null) return;

    setState(() {
      _startAt = picked;
    });
  }

  //PICK DEADLINE
  Future<void> _pickDeadlineDateTime() async {
    final picked = await _pickDateTime();
    if (picked == null) return;

    setState(() {
      _dueAt = picked;
    });
  }

  // SUBMIT
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startAt == null || _dueAt == null) {
      _showError('Vui lòng chọn ngày bắt đầu và kết thúc');
      return;
    }

    if (_dueAt!.isBefore(_startAt!)) {
      _showError('Deadline phải sau ngày bắt đầu');
      return;
    }

    // Lấy các reminder đã tick
    final selectedDays = _remindOptions.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedDays.isEmpty) {
      _showError('Vui lòng chọn ít nhất 1 mốc nhắc nhở');
      return;
    }

    // Tạo danh sách DateTime nhắc nhở
    final remindAtList = selectedDays
        .map((day) => _dueAt!.subtract(Duration(days: day)))
        .toList();

    // remindAt < dueAt
    if (remindAtList.any((r) => !r.isBefore(_dueAt!))) {
      _showError('Thời điểm nhắc nhở phải trước deadline');
      return;
    }

    final task = Task(
      title: _titleController.text,
      description: _descController.text,
      startAt: _startAt!,
      dueAt: _dueAt!,
      remindAt: remindAtList,
      priority: _priority,
      progress: _progress.toInt(),
    );

    await TaskService.addTask(task);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tạo task thành công (log console)')),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo deadline')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // TITLE
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tên công việc'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Không được bỏ trống' : null,
              ),

              const SizedBox(height: 12),

              // DESCRIPTION
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Mô tả'),
                maxLines: 3,
              ),

              const SizedBox(height: 12),

              // DATES
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStartDateTime,
                      child: Text(
                        _startAt == null
                            ? 'Ngày bắt đầu'
                            : _startAt!.toString().substring(0, 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickDeadlineDateTime,
                      child: Text(
                        _dueAt == null
                            ? 'Ngày kết thúc'
                            : _dueAt!.toString().substring(0, 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // PRIORITY
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Mức độ ưu tiên'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('High')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('Low')),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),

              const SizedBox(height: 12),

              // PROGRESS
              Text('Tiến độ: ${_progress.toInt()}%'),
              Slider(
                value: _progress,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (v) => setState(() => _progress = v),
              ),

              const SizedBox(height: 12),

              // REMINDER
              const Text(
                'Nhắc nhở trước deadline',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._remindOptions.keys.map(
                (day) => CheckboxListTile(
                  value: _remindOptions[day],
                  title: Text('Trước $day ngày'),
                  onChanged: (v) => setState(() => _remindOptions[day] = v!),
                ),
              ),

              const SizedBox(height: 20),

              // SAVE
              ElevatedButton(onPressed: _submit, child: const Text('Lưu')),
            ],
          ),
        ),
      ),
    );
  }
}
