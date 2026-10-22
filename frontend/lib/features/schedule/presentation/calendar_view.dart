import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../application/calendar_provider.dart';
import '../application/schedule_provider.dart';
import '../domain/calendar_model.dart';

class CalendarView extends ConsumerWidget {
  final VoidCallback onAddBlockPressed;
  final VoidCallback onSwitchToDailyPressed;

  const CalendarView({
    super.key,
    required this.onAddBlockPressed,
    required this.onSwitchToDailyPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMonth = ref.watch(calendarMonthProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final key = MonthYearKey(viewMonth.year, viewMonth.month);
    final eventsAsync = ref.watch(calendarEventsProvider(key));

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
      child: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error loading calendar: $err', style: const TextStyle(color: AppColors.error)),
        ),
        data: (events) => _buildCalendarBody(context, ref, viewMonth, selectedDate, events),
      ),
    );
  }

  Widget _buildCalendarBody(
    BuildContext context,
    WidgetRef ref,
    DateTime viewMonth,
    DateTime selectedDate,
    CalendarMonthEvents events,
  ) {
    final now = DateTime.now();
    final isCurrentMonth = viewMonth.year == now.year && viewMonth.month == now.month;

    // Aggregate monthly stats
    final totalMilestones = events.goals.length;
    final totalBlocks = events.scheduleBlocks.length;
    final totalStudySecs = events.studySessions.fold<int>(0, (s, e) => s + e.durationSeconds);
    final totalHours = (totalStudySecs / 3600).toStringAsFixed(1);

    return Column(
      children: [
        // ── Month Navigator & Stats Bar ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              // Month Switcher
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                color: AppColors.textDarkSecondary,
                tooltip: 'Previous Month',
                onPressed: () {
                  ref.read(calendarMonthProvider.notifier).state =
                      DateTime(viewMonth.year, viewMonth.month - 1, 1);
                },
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMMM yyyy').format(viewMonth),
                style: const TextStyle(
                  color: AppColors.textDarkPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                color: AppColors.textDarkSecondary,
                tooltip: 'Next Month',
                onPressed: () {
                  ref.read(calendarMonthProvider.notifier).state =
                      DateTime(viewMonth.year, viewMonth.month + 1, 1);
                },
              ),
              if (!isCurrentMonth) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ref.read(calendarMonthProvider.notifier).state =
                        DateTime(now.year, now.month, 1);
                  },
                  child: const Text('This Month', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ],

              const Spacer(),

              // Monthly Metrics Badges
              _MetricBadge(
                icon: Icons.flag_rounded,
                color: AppColors.warning,
                label: '$totalMilestones Milestones',
              ),
              const SizedBox(width: 14),
              _MetricBadge(
                icon: Icons.schedule_rounded,
                color: AppColors.primaryLight,
                label: '$totalBlocks Study Blocks',
              ),
              const SizedBox(width: 14),
              _MetricBadge(
                icon: Icons.timer_outlined,
                color: AppColors.success,
                label: '${totalHours}h Logged Study',
              ),
            ],
          ),
        ),

        // ── Main Calendar Grid & Day Inspector ──────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Monthly Calendar Grid (flex: 7)
              Expanded(
                flex: 7,
                child: _buildMonthGrid(context, ref, viewMonth, selectedDate, events),
              ),
              const SizedBox(width: 16),
              // Right: Selected Day Inspector (flex: 4)
              Expanded(
                flex: 4,
                child: _buildDayInspector(context, ref, selectedDate, events),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthGrid(
    BuildContext context,
    WidgetRef ref,
    DateTime viewMonth,
    DateTime selectedDate,
    CalendarMonthEvents events,
  ) {
    // Generate the days for the 7x5 or 7x6 grid
    final firstDayOfMonth = DateTime(viewMonth.year, viewMonth.month, 1);
    final daysInMonth = DateTime(viewMonth.year, viewMonth.month + 1, 0).day;
    // Weekday: 1 = Mon, 7 = Sun. Leading days offset = firstDayOfMonth.weekday - 1
    final leadingDays = firstDayOfMonth.weekday - 1;
    final totalCells = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          // Weekday Headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              children: weekdays
                  .map(
                    (w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: const TextStyle(
                            color: AppColors.textDarkMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Day Cells Grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.25,
              ),
              itemCount: totalCells,
              itemBuilder: (ctx, index) {
                final dayOffset = index - leadingDays + 1;
                final isCurrentMonth = dayOffset >= 1 && dayOffset <= daysInMonth;

                DateTime cellDate;
                if (dayOffset < 1) {
                  // Preceding month
                  final prevMonthDays = DateTime(viewMonth.year, viewMonth.month, 0).day;
                  cellDate = DateTime(viewMonth.year, viewMonth.month - 1, prevMonthDays + dayOffset);
                } else if (dayOffset > daysInMonth) {
                  // Next month
                  cellDate = DateTime(viewMonth.year, viewMonth.month + 1, dayOffset - daysInMonth);
                } else {
                  // Current month
                  cellDate = DateTime(viewMonth.year, viewMonth.month, dayOffset);
                }

                final cellDateStr = formatDate(cellDate);
                final isToday = formatDate(DateTime.now()) == cellDateStr;
                final isSelected = formatDate(selectedDate) == cellDateStr;

                final dayGoals = events.goalsForDate(cellDateStr);
                final dayBlocks = events.blocksForDate(cellDateStr);
                final dayStudySec = events.totalStudySecondsForDate(cellDateStr);

                return _DayCell(
                  date: cellDate,
                  dateStr: cellDateStr,
                  isCurrentMonth: isCurrentMonth,
                  isToday: isToday,
                  isSelected: isSelected,
                  goals: dayGoals,
                  blocks: dayBlocks,
                  studySeconds: dayStudySec,
                  onTap: () {
                    ref.read(selectedDateProvider.notifier).state = cellDate;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayInspector(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
    CalendarMonthEvents events,
  ) {
    final dateStr = formatDate(selectedDate);
    final goals = events.goalsForDate(dateStr);
    final blocks = events.blocksForDate(dateStr);
    final sessions = events.sessionsForDate(dateStr);
    final isToday = formatDate(DateTime.now()) == dateStr;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inspector Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                      style: const TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isToday ? 'Today\'s Schedule & Goals' : 'Day Summary',
                      style: TextStyle(
                        color: isToday ? AppColors.primary : AppColors.textDarkMuted,
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                color: AppColors.primary,
                tooltip: 'Open in Daily Schedule',
                onPressed: onSwitchToDailyPressed,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.darkBorder, height: 1),
          const SizedBox(height: 14),

          // Scrollable content
          Expanded(
            child: ListView(
              children: [
                // 1. Target Milestones
                _buildSectionHeader('Target Milestones', Icons.flag_rounded, AppColors.warning),
                const SizedBox(height: 8),
                if (goals.isEmpty)
                  _buildEmptyNotice('No milestones targeting this date')
                else
                  ...goals.map((g) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flag_rounded, size: 14, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                g.roadmapTitle,
                                style: const TextStyle(
                                  color: AppColors.textDarkPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),

                const SizedBox(height: 16),

                // 2. Study Blocks
                _buildSectionHeader('Scheduled Blocks', Icons.schedule_rounded, AppColors.primaryLight),
                const SizedBox(height: 8),
                if (blocks.isEmpty)
                  _buildEmptyNotice('No study blocks planned for this day')
                else
                  ...blocks.map((b) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.sidebarBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: b.isCompleted
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.darkBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await ref
                                    .read(scheduleNotifierProvider(dateStr).notifier)
                                    .toggleComplete(b.id, !b.isCompleted);
                                // Refresh month
                                ref.invalidate(calendarEventsProvider);
                              },
                              child: Icon(
                                b.isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                                size: 16,
                                color: b.isCompleted ? AppColors.success : AppColors.textDarkMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                b.title,
                                style: TextStyle(
                                  color: b.isCompleted
                                      ? AppColors.textDarkMuted
                                      : AppColors.textDarkPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  decoration: b.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${b.startTime} - ${b.endTime}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      )),

                const SizedBox(height: 16),

                // 3. Logged Study Sessions
                _buildSectionHeader('Logged Study Time', Icons.timer_outlined, AppColors.success),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  _buildEmptyNotice('No study sessions logged')
                else
                  ...sessions.map((s) {
                    final mins = (s.durationSeconds / 60).round();
                    final timeDisplay = mins >= 60
                        ? '${mins ~/ 60}h ${mins % 60}m'
                        : '${mins}m';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.topicTitle,
                              style: const TextStyle(
                                color: AppColors.textDarkPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              timeDisplay,
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Bottom Action: Add Block
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddBlockPressed,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Time Block for This Day'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyNotice(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textDarkMuted,
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MetricBadge({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final String dateStr;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final List<CalendarGoalItem> goals;
  final List<CalendarScheduleItem> blocks;
  final int studySeconds;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.dateStr,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.goals,
    required this.blocks,
    required this.studySeconds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = Colors.transparent;
    Color bgColor = Colors.transparent;

    if (isSelected) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withValues(alpha: 0.15);
    } else if (isToday) {
      borderColor = AppColors.accent;
      bgColor = AppColors.accent.withValues(alpha: 0.05);
    }

    final textColor = isCurrentMonth
        ? (isSelected ? AppColors.primaryLight : AppColors.textDarkPrimary)
        : AppColors.textDarkMuted.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (isToday)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),

            // Badges / Indicators
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Goal indicator
                    if (goals.isNotEmpty)
                      _BadgePill(
                        color: AppColors.warning,
                        icon: Icons.flag_rounded,
                        text: goals.length == 1 ? goals.first.roadmapTitle : '${goals.length} Goals',
                      ),

                    // Block indicator
                    if (blocks.isNotEmpty)
                      _BadgePill(
                        color: AppColors.primaryLight,
                        icon: Icons.schedule_rounded,
                        text: '${blocks.length} block${blocks.length > 1 ? 's' : ''}',
                      ),

                    // Study session logged
                    if (studySeconds > 0)
                      _BadgePill(
                        color: AppColors.success,
                        icon: Icons.timer_outlined,
                        text: _formatMinutes(studySeconds),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int totalSecs) {
    final mins = (totalSecs / 60).round();
    if (mins >= 60) {
      return '${mins ~/ 60}h ${mins % 60}m';
    }
    return '${mins}m';
  }
}

class _BadgePill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _BadgePill({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
