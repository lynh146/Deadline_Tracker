import '../models/deadline_task.dart';
import '../repositories/task_repository.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'notification_service.dart';

class TaskService {
  TaskService(this._repo);

  final TaskRepository _repo;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // lấy tất cả task của user dưới dạng stream
  Stream<List<Task>> watchAllTasks(String userId) {
    return _repo.watchTasksByUser(userId);
  }

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) => _startOfDay(d).add(const Duration(days: 1));

  DateTime _startOfWeek(DateTime d) =>
      _startOfDay(d).subtract(Duration(days: d.weekday - DateTime.monday));

  DateTime _endOfWeek(DateTime d) =>
      _startOfWeek(d).add(const Duration(days: 7));

  bool _inRange(DateTime x, DateTime s, DateTime e) =>
      !x.isBefore(s) && x.isBefore(e);
  // lọc các task trong ngày
  Stream<List<Task>> watchTodayTasks(String userId) {
    return watchAllTasks(userId).map((all) {
      final now = DateTime.now();
      final start = _startOfDay(now);
      final end = _endOfDay(now);

      final list =
          all
              .where((t) => _inRange(t.dueAt, start, end) && !t.isCompleted)
              .toList()
            ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

      return list;
    });
  }

  // đếm số task trong tuần
  Stream<int> watchWeeklyTasksCount(String userId) {
    return watchAllTasks(userId).map((all) {
      final now = DateTime.now();
      return all
          .where(
            (t) =>
                !t.isCompleted &&
                _inRange(t.dueAt, _startOfWeek(now), _endOfWeek(now)),
          )
          .length;
    });
  }

  // lọc theo trạng thái
  List<Task> filterByStatus(List<Task> all, TaskStatus status) {
    final list = all.where((t) => t.status == status).toList();
    list.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return list;
  }

  // lấy các task chưa làm
  List<Task> filterNotStarted(List<Task> all) {
    final now = DateTime.now();
    final list =
        all
            .where(
              (t) => !t.isCompleted && t.progress == 0 && t.dueAt.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return list;
  }

  // lấy các task đang làm và sắp đến hạn
  List<Task> filterInProgressSorted(List<Task> all) {
    final list = all.where((t) => t.isInProgress).toList()
      ..sort((a, b) {
        final c = a.dueAt.compareTo(b.dueAt);
        if (c != 0) return c;
        return a.progress.compareTo(b.progress);
      });
    return list;
  }

  // lấy các task sắp đến hạn trong vài ngày tới
  List<Task> filterDueSoon(List<Task> all, {required int days}) {
    final now = DateTime.now();
    final day = _startOfDay(now).add(Duration(days: days));
    final start = day;
    final end = _endOfDay(day);

    final list =
        all
            .where(
              (t) =>
                  !t.isCompleted &&
                  !t.isOverdue &&
                  _inRange(t.dueAt, start, end),
            )
            .toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return list;
  }

  // lấy vài task sắp đến hạn nhất
  List<Task> filterDueSoonLatest(List<Task> all, {int limit = 2}) {
    final merged = [
      ...filterDueSoon(all, days: 1),
      ...filterDueSoon(all, days: 3),
      ...filterDueSoon(all, days: 5),
    ];

    final seen = <String>{};
    final distinct = <Task>[];
    for (final t in merged) {
      if (seen.add(t.id ?? '${t.title}-${t.dueAt}')) distinct.add(t);
    }

    distinct.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return distinct.take(limit).toList();
  }

  // notification

  int _notifId(String docId, int salt) => (docId.hashCode & 0x7fffffff) + salt;
  // bắt đầu
  Future<void> _scheduleStart({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    if (task.startAt.isAfter(DateTime.now())) {
      final title = 'Hôm nay bắt đầu ${task.title}';
      final body = task.title;

      await NotificationService.instance.schedule(
        id: _notifId(docId, 100),
        title: title,
        body: body,
        time: task.startAt,
        channelId: NotificationService.chStart,
        channelName: 'Start',
        channelDesc: 'Start task',
      );

      await NotificationService.instance.saveToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: 'start',
        createdAt: DateTime.now(),
        scheduledFor: task.startAt,
        taskDocId: docId,
      );
    }
  }

  // nhắc nhở
  Future<void> _scheduleReminders({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    for (int i = 0; i < task.remindAt.length; i++) {
      final t = task.remindAt[i];
      if (t.isBefore(DateTime.now()) || !t.isBefore(task.dueAt)) continue;

      final daysLeft = task.dueAt.difference(t).inDays;
      final title = 'Còn $daysLeft ngày đến hạn ${task.title}';
      final body = task.title;

      await NotificationService.instance.schedule(
        id: _notifId(docId, i + 1),
        title: title,
        body: body,
        time: t,
        channelId: NotificationService.chReminder,
        channelName: 'Reminder',
        channelDesc: 'Reminder',
      );

      await NotificationService.instance.saveToFirestore(
        userId: userId,
        title: title,
        body: body,
        type: 'reminder',
        createdAt: DateTime.now(),
        scheduledFor: t,
        taskDocId: docId,
      );
    }
  }

  // deadline và overdue
  Future<void> _scheduleDeadline({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    final dueTitle = 'Đến hạn ${task.title}';
    final body = task.title;

    await NotificationService.instance.schedule(
      id: _notifId(docId, 0),
      title: dueTitle,
      body: body,
      time: task.dueAt,
      channelId: NotificationService.chDeadline,
      channelName: 'Deadline',
      channelDesc: 'Deadline',
    );

    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: dueTitle,
      body: body,
      type: 'deadline',
      createdAt: DateTime.now(),
      scheduledFor: task.dueAt,
      taskDocId: docId,
    );

    final overdueTime = task.dueAt.add(const Duration(minutes: 1));
    final overdueTitle = '${task.title} đã hết hạn';

    await NotificationService.instance.schedule(
      id: _notifId(docId, 200),
      title: overdueTitle,
      body: body,
      time: overdueTime,
      channelId: NotificationService.chOverdue,
      channelName: 'Overdue',
      channelDesc: 'Overdue',
    );

    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: overdueTitle,
      body: body,
      type: 'overdue',
      createdAt: DateTime.now(),
      scheduledFor: overdueTime,
      taskDocId: docId,
    );
  }

  // hủy tất cả noti liên quan task
  Future<void> _cancelAllTaskNotifs(String docId) async {
    for (int i = 0; i <= 3; i++) {
      await NotificationService.instance.cancel(_notifId(docId, i));
    }
    await NotificationService.instance.cancel(_notifId(docId, 100));
    await NotificationService.instance.cancel(_notifId(docId, 200));
  }

  // tạo

  Future<void> createTask({required String userId, required Task task}) async {
    final docId = await _repo.addTask(userId: userId, task: task);

    final title = 'Đã tạo ${task.title}';
    final body = task.title;

    await NotificationService.instance.showNow(
      id: _notifId(docId, 999),
      title: title,
      body: body,
      channelId: NotificationService.chGeneral,
      channelName: 'General',
      channelDesc: 'General',
    );

    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: title,
      body: body,
      type: 'create',
      createdAt: DateTime.now(),
      taskDocId: docId,
    );

    await _scheduleStart(userId: userId, docId: docId, task: task);
    await _scheduleReminders(userId: userId, docId: docId, task: task);
    await _scheduleDeadline(userId: userId, docId: docId, task: task);
  }

  // cập nhật
  Future<void> updateTask({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    final old = await _repo.getTaskById(docId: docId);
    await _repo.updateTask(docId: docId, task: task);

    final title = 'Đã cập nhật ${task.title}';
    final body = task.title;
    await NotificationService.instance.showNow(
      id: _notifId(docId, 888),
      title: title,
      body: body,
      channelId: NotificationService.chProgress,
      channelName: 'Update',
      channelDesc: 'Update',
    );

    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: title,
      body: body,
      type: 'update',
      createdAt: DateTime.now(),
      taskDocId: docId,
    );

    await _cancelAllTaskNotifs(docId);
    await _scheduleStart(userId: userId, docId: docId, task: task);
    await _scheduleReminders(userId: userId, docId: docId, task: task);
    await _scheduleDeadline(userId: userId, docId: docId, task: task);

    if (task.progress == 100 && old?.progress != 100) {
      await _analytics.logEvent(name: 'complete_task');
    }
  }

  // xóa
  Future<void> deleteTask({
    required String userId,
    required String docId,
    required Task task,
  }) async {
    await _repo.deleteTask(docId);
    await _cancelAllTaskNotifs(docId);

    final title = 'Đã xoá ${task.title}';
    final body = task.title;

    await NotificationService.instance.saveToFirestore(
      userId: userId,
      title: title,
      body: body,
      type: 'delete',
      createdAt: DateTime.now(),
      taskDocId: docId,
    );
  }
}
