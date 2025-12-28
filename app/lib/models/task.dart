class Task {
  int? id;
  String title;
  String description;
  DateTime startAt;
  DateTime dueAt;
  DateTime remindAt;
  int priority;
  int progress;
  int status;

  Task({
    this.id,
    required this.title,
    required this.description,
    required this.startAt,
    required this.dueAt,
    required this.remindAt,
    this.priority = 1,
    this.progress = 0,
    this.status = 0,
  });
}
