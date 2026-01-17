import 'package:app/core/theme/app_colors.dart';
import 'package:app/screens/calendar/calendar_month_screen.dart';
import 'package:app/screens/calendar/calendar_week_screen.dart';
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isMonthView = true;
  DateTime _focusedDay = DateTime.now();

  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      _focusedDay = selectedDay;
      _isMonthView = false;
    });
  }

  void _showMonthView() {
    setState(() {
      _isMonthView = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: !_isMonthView
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: _showMonthView,
        )
            : null,
        title: const Text(
          'Lịch',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              // TODO: Handle notification tap
            },
          ),
        ],
      ),
      body: _isMonthView
          ? CalendarMonthScreen(onDaySelected: _onDaySelected)
          : CalendarWeekScreen(
        focusedDay: _focusedDay,
        onDaySelected: _onDaySelected,
      ),
    );
  }
}
