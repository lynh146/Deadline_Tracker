class Task {
  final int? id;
  final String title;
  final String description;
  final DateTime startAt;
  final DateTime dueAt;
  final List<DateTime> remindAt;
  final int priority;
  final int progress;
  final int status;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.dueAt,
    required this.remindAt,
    required this.priority,
    this.progress = 0,
    this.status = 0,
  });

  @override
  String toString() {
    return '''
Task(
  title: $title,
  startAt: $startAt,
  dueAt: $dueAt,
  remindAt: $remindAt,
  priority: $priority
)
''';
  }
}
