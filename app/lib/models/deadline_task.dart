import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum TaskStatus {
  completed, // progress == 100
  overdue, // quá dueAt
  inProgress, // 1–99%
  upcoming, // ch làm (progress == 0) và chưa overdue
}

class Task {
  final String? id;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime dueAt;
  final List<DateTime> remindAt;
  final int progress;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.dueAt,
    required this.remindAt,
    required this.progress,
  });

  // TÍNH TRẠNG THÁI TASK
  // - completed : progress == 100
  // - overdue   : quá hạn thời gian (now > dueAt) và chưa hoàn thành
  // - upcoming  : ch làm (progress == 0) và chưa overdue
  // - inProgress: 1–99% và chưa overdue

  TaskStatus get status {
    final now = DateTime.now();

    if (progress >= 100) return TaskStatus.completed;
    if (dueAt.isBefore(now)) return TaskStatus.overdue;
    if (progress == 0) return TaskStatus.upcoming;
    return TaskStatus.inProgress;
  }

  // MÀU PROGRESS BAR
  // 0–29%  : đỏ
  // 30–79% : vàng
  // 80–100%: xanh

  Color get progressColor {
    if (progress < 30) return AppColors.progressLow;
    if (progress < 80) return AppColors.progressMedium;
    return AppColors.progressHigh;
  }

  bool get isOverdue => status == TaskStatus.overdue;
  bool get isCompleted => status == TaskStatus.completed;
  bool get isInProgress => status == TaskStatus.inProgress;
  bool get isUpcoming => status == TaskStatus.upcoming;

  @override
  String toString() {
    return '''
Task(
  id: $id,
  title: $title,
  startAt: $startAt,
  dueAt: $dueAt,
  progress: $progress,
  status: $status
)
''';
  }
}
