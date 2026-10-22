import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/calendar_provider.dart';
import '../application/schedule_provider.dart';
import '../domain/schedule_model.dart';
import 'calendar_view.dart';

enum ScheduleViewMode { daily, calendar }

final scheduleViewModeProvider =
    StateProvider<ScheduleViewMode>((ref) => ScheduleViewMode.daily);

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(scheduleViewModeProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr = formatDate(selectedDate);
    final blocksAsync = ref.watch(scheduleNotifierProvider(dateStr));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Area ───────────────────────────────────────────────────
          _buildHeader(context, selectedDate, dateStr, viewMode),

          // ── Content Area ──────────────────────────────────────────────────
          Expanded(
            child: viewMode == ScheduleViewMode.daily
                ? blocksAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
                    ),
                    data: (blocks) => _buildScheduleContent(context, blocks, dateStr),
                  )
                : CalendarView(
                    onAddBlockPressed: () => _showAddEditBlockDialog(context, dateStr),
                    onSwitchToDailyPressed: () {
                      ref.read(scheduleViewModeProvider.notifier).state =
                          ScheduleViewMode.daily;
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DateTime selectedDate,
    String dateStr,
    ScheduleViewMode viewMode,
  ) {
    final isToday = formatDate(DateTime.now()) == dateStr;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
      child: Row(
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewMode == ScheduleViewMode.daily
                      ? 'Daily Study Schedule'
                      : 'Target Milestones & Calendar',
                  style: const TextStyle(
                    color: AppColors.textDarkPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  viewMode == ScheduleViewMode.daily
                      ? 'Plan and track your hourly study blocks'
                      : 'Milestone deadlines, study blocks, and logged hours',
                  style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // View Mode Switcher
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewToggleButton(
                  icon: Icons.view_day_outlined,
                  label: 'Daily Blocks',
                  isSelected: viewMode == ScheduleViewMode.daily,
                  onTap: () {
                    ref.read(scheduleViewModeProvider.notifier).state =
                        ScheduleViewMode.daily;
                  },
                ),
                const SizedBox(width: 4),
                _ViewToggleButton(
                  icon: Icons.calendar_month_outlined,
                  label: 'Calendar View',
                  isSelected: viewMode == ScheduleViewMode.calendar,
                  onTap: () {
                    ref.read(scheduleViewModeProvider.notifier).state =
                        ScheduleViewMode.calendar;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Date Navigator (Only in Daily view)
          if (viewMode == ScheduleViewMode.daily) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 20),
                    color: AppColors.textDarkSecondary,
                    tooltip: 'Previous Day',
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          selectedDate.subtract(const Duration(days: 1));
                    },
                  ),
                  InkWell(
                    onTap: () => _pickDate(context, selectedDate),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            isToday ? 'Today, $dateStr' : dateStr,
                            style: TextStyle(
                              color: isToday ? AppColors.primary : AppColors.textDarkPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 20),
                    color: AppColors.textDarkSecondary,
                    tooltip: 'Next Day',
                    onPressed: () {
                      ref.read(selectedDateProvider.notifier).state =
                          selectedDate.add(const Duration(days: 1));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Jump to Today button
            if (!isToday) ...[
              OutlinedButton(
                onPressed: () {
                  ref.read(selectedDateProvider.notifier).state = DateTime.now();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.darkBorder),
                  foregroundColor: AppColors.textDarkSecondary,
                ),
                child: const Text('Today'),
              ),
              const SizedBox(width: 12),
            ],
          ],

          // Add Block Button
          ElevatedButton.icon(
            onPressed: () => _showAddEditBlockDialog(context, dateStr),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Time Block'),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent(
      BuildContext context, List<ScheduleBlockModel> blocks, String dateStr) {
    if (blocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Icon(Icons.access_time_outlined, size: 48, color: AppColors.textDarkMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'No study blocks for this day',
              style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Block out focused time for your study topics and habits.',
              style: TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddEditBlockDialog(context, dateStr),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Schedule First Block'),
            ),
          ],
        ),
      );
    }

    final completedCount = blocks.where((b) => b.isCompleted).length;
    final totalCount = blocks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // Daily Progress Summary Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Plan Completion: $completedCount of $totalCount blocks done',
                            style: const TextStyle(
                              color: AppColors.textDarkPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.darkBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chronological Time Blocks List
          Expanded(
            child: ListView.builder(
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                final block = blocks[index];
                return _ScheduleBlockCard(block: block, dateStr: dateStr);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }

  void _showAddEditBlockDialog(BuildContext context, String defaultDate,
      {ScheduleBlockModel? editBlock}) {
    final titleCtrl = TextEditingController(text: editBlock?.title ?? '');
    final startCtrl = TextEditingController(text: editBlock?.startTime ?? '09:00');
    final endCtrl = TextEditingController(text: editBlock?.endTime ?? '10:30');
    final notesCtrl = TextEditingController(text: editBlock?.notes ?? '');
    int? selectedTopicId = editBlock?.topicId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.darkCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            editBlock == null ? 'New Study Block' : 'Edit Study Block',
            style: const TextStyle(color: AppColors.textDarkPrimary),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: AppColors.textDarkPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Block Title *',
                      hintText: 'e.g. Concurrency & Arc Patterns',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startCtrl,
                          style: const TextStyle(color: AppColors.textDarkPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Start Time (HH:MM) *',
                            hintText: '09:00',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: endCtrl,
                          style: const TextStyle(color: AppColors.textDarkPrimary),
                          decoration: const InputDecoration(
                            labelText: 'End Time (HH:MM) *',
                            hintText: '10:30',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesCtrl,
                    style: const TextStyle(color: AppColors.textDarkPrimary),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Objectives / Notes (Optional)',
                      hintText: 'e.g. Read chapter 4, solve 2 exercises',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final start = startCtrl.text.trim();
                final end = endCtrl.text.trim();
                if (title.isEmpty || start.isEmpty || end.isEmpty) return;

                if (editBlock == null) {
                  await ref.read(scheduleNotifierProvider(defaultDate).notifier).addBlock(
                        scheduledDate: defaultDate,
                        startTime: start,
                        endTime: end,
                        title: title,
                        topicId: selectedTopicId,
                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                      );
                } else {
                  await ref.read(scheduleNotifierProvider(defaultDate).notifier).updateBlock(
                    editBlock.id,
                    {
                      'title': title,
                      'start_time': start,
                      'end_time': end,
                      'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                    },
                  );
                }
                ref.invalidate(calendarEventsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(editBlock == null ? 'Schedule' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : AppColors.textDarkSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textDarkSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleBlockCard extends ConsumerWidget {
  final ScheduleBlockModel block;
  final String dateStr;
  const _ScheduleBlockCard({required this.block, required this.dateStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: block.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.darkBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(scheduleNotifierProvider(dateStr).notifier)
                      .toggleComplete(block.id, !block.isCompleted);
                  ref.invalidate(calendarEventsProvider);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: block.isCompleted ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: block.isCompleted ? AppColors.success : AppColors.textDarkMuted,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: block.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Time Column
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sidebarBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Text(
                '${block.startTime} - ${block.endTime}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.title,
                    style: TextStyle(
                      color: block.isCompleted
                          ? AppColors.textDarkMuted
                          : AppColors.textDarkPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: block.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (block.notes != null && block.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      block.notes!,
                      style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              color: AppColors.textDarkMuted,
              tooltip: 'Delete Block',
              onPressed: () async {
                await ref
                    .read(scheduleNotifierProvider(dateStr).notifier)
                    .deleteBlock(block.id);
                ref.invalidate(calendarEventsProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}

