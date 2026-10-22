import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/timer_provider.dart';

class ActiveStudyTimerBar extends ConsumerWidget {
  const ActiveStudyTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(studyTimerProvider);

    if (timerState.activeTopicId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        border: const Border(
          top: BorderSide(color: AppColors.primary, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pulsing status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: timerState.isRunning ? AppColors.success : AppColors.warning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (timerState.isRunning ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Active Topic Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      timerState.isRunning ? 'FOCUS TIMER ACTIVE' : 'TIMER PAUSED',
                      style: TextStyle(
                        color: timerState.isRunning ? AppColors.success : AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  timerState.activeTopicTitle ?? 'Study Session',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDarkPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Large Monospace Timer Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.sidebarBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Text(
              timerState.formattedTime,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Play / Pause Button
          IconButton(
            icon: Icon(
              timerState.isRunning ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 28,
              color: AppColors.primary,
            ),
            tooltip: timerState.isRunning ? 'Pause' : 'Resume',
            onPressed: () {
              if (timerState.isRunning) {
                ref.read(studyTimerProvider.notifier).pauseTimer();
              } else {
                ref.read(studyTimerProvider.notifier).resumeTimer();
              }
            },
          ),
          const SizedBox(width: 8),

          // Finish & Log Button
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Finish & Log'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => _showSaveSessionDialog(context, ref, timerState),
          ),
          const SizedBox(width: 8),

          // Discard Button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textDarkMuted,
            tooltip: 'Discard Timer',
            onPressed: () {
              ref.read(studyTimerProvider.notifier).resetTimer();
            },
          ),
        ],
      ),
    );
  }

  void _showSaveSessionDialog(BuildContext context, WidgetRef ref, TimerState timerState) {
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.timer, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text(
              'Log Study Session',
              style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Topic: ${timerState.activeTopicTitle ?? ""}',
              style: const TextStyle(color: AppColors.textDarkPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Duration: ${timerState.formattedTime} (${(timerState.elapsedSeconds / 60).ceil()} minutes)',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textDarkPrimary),
              decoration: const InputDecoration(
                labelText: 'Session Notes / Highlights (Optional)',
                hintText: 'e.g. Mastered borrow rules, fixed lifetime errors in test suite',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final notes = notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim();
              await ref.read(studyTimerProvider.notifier).saveAndLogSession(notes);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Study session logged successfully!'),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save to Log'),
          ),
        ],
      ),
    );
  }
}
