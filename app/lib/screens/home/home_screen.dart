import 'package:flutter/material.dart';
import '../calendar/calendar_screen.dart';
import '../add_task/add_task_screen.dart';
import '../stats/stats_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final List<Widget> _tabs = const [
    _HomeTab(),
    CalendarScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  void _onFabTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AddTaskScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabTap,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'Home',
                active: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                icon: Icons.calendar_month,
                label: 'Calendar',
                active: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              const SizedBox(width: 40),
              _NavItem(
                icon: Icons.bar_chart,
                label: 'Stats',
                active: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                icon: Icons.person,
                label: 'Profile',
                active: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.blue : Colors.grey;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

// test
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  @override
  void initState() {
    super.initState();
    _testDb();
  }

  Future<void> _testDb() async {
    final tasks = await TaskService.getAllTasks();
    print('TASKS IN DB: ${tasks.length}');
    for (final t in tasks) {
      print('• ${t.title}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Home Tab')));
  }
}
