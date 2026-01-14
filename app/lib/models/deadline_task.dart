/// Model + logic dùng chung cho toàn app
/// - Không phụ thuộc UI
/// - Không filter theo từng màn hình cụ thể
/// - Chỉ cung cấp:
///   + Enum trạng thái
///   + Helper tính màu progress
///   + Helper kiểm tra trạng thái (hoàn thành / hết hạn / đang làm)

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// ENUM TRẠNG THÁI TASK (NGHIỆP VỤ)
///
/// LƯU Ý:
/// - Đây là trạng thái LOGIC, KHÔNG PHẢI màu progress
/// - Mỗi màn hình sẽ filter theo enum này theo cách riêng
///
enum TaskStatus {
  completed, // progress == 100
  overdue, // quá dueAt
  inProgress, // 1–99%
  upcoming, // chưa tới hạn (future)
}

/// MODEL TASK
class Task {
  final int? id;

  /// Tiêu đề công việc
  final String title;

  /// Mô tả chi tiết
  final String description;

  /// Thời điểm bắt đầu
  final DateTime startAt;

  /// Thời điểm phải hoàn thành
  final DateTime dueAt;

  /// Danh sách thời điểm nhắc nhở
  final List<DateTime> remindAt;

  /// Tiến độ hoàn thành (%)
  /// 0 → 100
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

  /// TÍNH TRẠNG THÁI TASK
  ///
  /// Quy ước CHUNG cho toàn app:
  /// - completed : progress == 100
  /// - overdue   : quá hạn thời gian
  /// - inProgress: 1–99%
  /// - upcoming  : chưa tới hạn & progress == 0
  ///
  TaskStatus get status {
    final now = DateTime.now();

    if (progress >= 100) return TaskStatus.completed;
    if (dueAt.isBefore(now)) return TaskStatus.overdue;
    if (progress > 0) return TaskStatus.inProgress;
    return TaskStatus.upcoming;
  }

  /// MÀU PROGRESS BAR (THEO FIGMA)
  ///
  /// DÙNG CHUNG cho:
  /// - Home
  /// - Detail
  /// - Update
  ///
  /// Quy ước:
  /// 0–29%  : đỏ
  /// 30–79% : vàng
  /// 80–100%: xanh
  ///
  Color get progressColor {
    if (progress < 30) return AppColors.progressLow;
    if (progress < 80) return AppColors.progressMedium;
    return AppColors.progressHigh;
  }

  /// KIỂM TRA CƠ BẢN (HELPER)

  /// Task có phải hết hạn không
  bool get isOverdue => status == TaskStatus.overdue;

  /// Task đã hoàn thành chưa
  bool get isCompleted => status == TaskStatus.completed;

  /// Task đang làm (1–99%)
  bool get isInProgress => status == TaskStatus.inProgress;

  /// Task chưa tới hạn
  bool get isUpcoming => status == TaskStatus.upcoming;

  /// DÙNG CHO DEBUG
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
