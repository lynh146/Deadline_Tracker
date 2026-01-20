import 'package:flutter/material.dart';
import '../../models/deadline_task.dart';

class StatusListScreen extends StatelessWidget {
  final String title;
  final List<Task> tasks;

  const StatusListScreen({super.key, required this.title, required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1D0FF),
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (_, i) {
          final task = tasks[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: task.progress / 100),
              ],
            ),
          );
        },
      ),
    );
  }
}
