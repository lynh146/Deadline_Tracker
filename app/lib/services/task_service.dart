import '../models/task.dart';

class TaskService {
  static Future<void> addTask(Task task) async {
    print('Add task called:');
    print(task);
  }
}
