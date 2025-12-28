import '../screens/home/home_screen.dart';
import '../screens/add_task/add_task_screen.dart';
import '../screens/calendar/celendar_screen.dart';

class AppRoutes {
  static const home = '/';
  static const addTask = '/add';
  static const calendar = '/calendar';
  static const stats = '/stats';
  static const profile = '/profile';

  static final routes = {
    home: (context) => const HomeScreen(),
    addTask: (context) => const AddTaskScreen(),
    calendar: (context) => const CalendarScreen(),
  };
}
