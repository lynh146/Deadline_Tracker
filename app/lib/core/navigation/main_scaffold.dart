import 'package:flutter/material.dart';
import 'bottom_nav.dart';

import '../../screens/home/home_screen.dart';
import '../../screens/calendar/calendar_screen.dart';
import '../../screens/stats/stats_screen.dart';
import '../../screens/profile/profile_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final _pages = const [
    HomeScreen(),
    CalendarScreen(),
    SizedBox(), // +
    StatsScreen(),
    ProfileScreen(),
  ];

  void _onTabChanged(int index) {
    if (index == 2) {
      // TODO: mở CreateTask
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D0FF), // nền figma
      body: Stack(
        children: [
          Positioned.fill(child: _pages[_currentIndex]),

          // gắn sát đáy như figma
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNav(currentIndex: _currentIndex, onTap: _onTabChanged),
          ),
        ],
      ),
    );
  }
}
