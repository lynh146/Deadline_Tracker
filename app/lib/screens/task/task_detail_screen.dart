import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/task_service.dart';
import '../../core/theme/app_colors.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Future<Task?>? _future;

  @override
  void initState() {
    super.initState();
    _future = TaskService.getTaskById(widget.taskId);
  }

  String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    _future ??= TaskService.getTaskById(widget.taskId);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FutureBuilder<Task?>(
          future: _future!,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Lỗi: ${snap.error}'));
            }

            final task = snap.data;
            if (task == null) {
              return const Center(child: Text('Không tìm thấy task'));
            }

            final progress = (task.progress.clamp(0, 100)) / 100.0;

            return Column(
              children: [
                // TOP BAR (back + title + bell)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.arrow_back_ios_new, size: 24),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Chi tiết',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(999),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.notifications_none, size: 30),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // BIG CARD
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 520),
                        padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
                        decoration: BoxDecoration(
                          color: AppColors.cardBig,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 18,
                              offset: Offset(0, 10),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              task.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 18),

                            // DATES
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: _DateMiniBox(
                                      label: 'Bắt đầu',
                                      value: _fmtDate(task.startAt),
                                      valueColor: AppColors.dateText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 28),
                                    child: _DateMiniBox(
                                      label: 'Kết thúc',
                                      value: _fmtDate(task.dueAt),
                                      valueColor: AppColors.dateText,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // PROGRESS BOX
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.progressBox,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 12,
                                    offset: Offset(0, 8),
                                    color: Color(0x14000000),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Tiến độ hoàn thành',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${task.progress}%',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: AppColors.barBg,
                                      valueColor: const AlwaysStoppedAnimation(
                                        AppColors.medium,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // DESCRIPTION (đúng vị trí dưới tiến độ)
                            _DescriptionBox(text: task.description),

                            const Spacer(),
                            SizedBox(
                              width: 260,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text(
                                  'Cập nhật',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: 260,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text(
                                  'Xóa',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ),
    );
  }
}

// MINI BOX FOR DATES
class _DateMiniBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DateMiniBox({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// DESCRIPTION BOX
class _DescriptionBox extends StatelessWidget {
  final String text;
  const _DescriptionBox({required this.text});

  @override
  Widget build(BuildContext context) {
    final showText = text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      constraints: const BoxConstraints(minHeight: 92),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 8),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showText.isEmpty ? ' ' : showText,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.35,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
