import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/study_hours_provider.dart';
import '../domain/study_hours_model.dart';

class StudyHoursDistributionCard extends ConsumerWidget {
  final int? roadmapId;

  const StudyHoursDistributionCard({super.key, this.roadmapId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(studyHoursMonthProvider);
    final filter = StudyHoursFilter(
      year: selectedDate.year,
      month: selectedDate.month,
      roadmapId: roadmapId,
    );
    final studyHoursAsync = ref.watch(studyHoursProvider(filter));

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row with Month Controls ────────────────────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Study Hours Distribution',
                      style: TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Study duration distribution, daily volume, and productive weekday habits',
                      style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              _buildMonthNavigator(context, ref, selectedDate),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.darkBorder, height: 1),
          const SizedBox(height: 20),

          studyHoursAsync.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Unable to load study hours distribution: $err',
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ),
            data: (model) => _buildContent(context, model),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator(BuildContext context, WidgetRef ref, DateTime currentDate) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18, color: AppColors.textDarkSecondary),
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
            tooltip: 'Previous Month',
            onPressed: () {
              ref.read(studyHoursMonthProvider.notifier).state =
                  DateTime(currentDate.year, currentDate.month - 1);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _formatMonthYear(currentDate),
              style: const TextStyle(
                color: AppColors.textDarkPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18, color: AppColors.textDarkSecondary),
            splashRadius: 18,
            visualDensity: VisualDensity.compact,
            tooltip: 'Next Month',
            onPressed: () {
              ref.read(studyHoursMonthProvider.notifier).state =
                  DateTime(currentDate.year, currentDate.month + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, MonthlyStudyHoursModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Metrics Ribbon ──────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.timer_outlined,
                iconColor: AppColors.accent,
                label: 'Total Studied',
                value: '${model.totalHours}h',
                subtitle: '${model.totalSessions} sessions logged',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFF10B981),
                label: 'Active Days',
                value: '${model.activeDaysCount} / ${model.totalDaysInMonth}',
                subtitle: model.totalDaysInMonth > 0
                    ? '${((model.activeDaysCount / model.totalDaysInMonth) * 100).toStringAsFixed(0)}% month consistency'
                    : 'No activity',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.speed_outlined,
                iconColor: AppColors.primaryLight,
                label: 'Daily Average',
                value: '${model.dailyAverageHours}h',
                subtitle: 'Per active day',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.star_border_rounded,
                iconColor: const Color(0xFFF59E0B),
                label: 'Peak Day',
                value: model.peakDayHours > 0 ? '${model.peakDayHours}h' : '—',
                subtitle: model.peakDayDate != null
                    ? _formatDateLabel(model.peakDayDate!)
                    : 'No peak day',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Daily Hours Bar Chart / Histogram ───────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.sidebarBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Daily Study Volume (${model.monthName})',
                    style: const TextStyle(
                      color: AppColors.textDarkSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Hours / Day',
                    style: TextStyle(
                      color: AppColors.textDarkMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDailyHistogram(model),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Dual Breakdown Section (Topics & Weekday Patterns) ───────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Top Topics (flex: 6)
            Expanded(
              flex: 6,
              child: _buildTopicBreakdown(model),
            ),
            const SizedBox(width: 20),
            // Right: Weekday Distribution (flex: 5)
            Expanded(
              flex: 5,
              child: _buildWeekdayBreakdown(model),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyHistogram(MonthlyStudyHoursModel model) {
    if (model.totalHours == 0) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty_rounded, size: 28, color: AppColors.textDarkMuted),
            const SizedBox(height: 8),
            Text(
              'No study sessions logged in ${model.monthName}.',
              style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final maxHours = model.dailyDistribution.isEmpty
        ? 1.0
        : math.max(
            0.5,
            model.dailyDistribution
                .map((d) => d.studyHours)
                .reduce((a, b) => math.max(a, b)),
          );

    return SizedBox(
      height: 95,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: model.dailyDistribution.map((item) {
          final isStudied = item.studyHours > 0;
          final heightFactor = (item.studyHours / maxHours).clamp(0.06, 1.0);

          return Expanded(
            child: Tooltip(
              message:
                  '${item.dayLabel}, ${item.date}\n• ${item.studyHours}h studied\n• ${item.sessionCount} sessions',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 58,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 8,
                        height: math.max(4.0, 58.0 * heightFactor),
                        decoration: BoxDecoration(
                          gradient: isStudied
                              ? const LinearGradient(
                                  colors: [AppColors.accent, AppColors.primary],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              : null,
                          color: isStudied ? null : AppColors.darkCardHover,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.dayOfMonth}',
                    style: TextStyle(
                      color: isStudied
                          ? AppColors.textDarkPrimary
                          : AppColors.textDarkMuted.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: isStudied ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopicBreakdown(MonthlyStudyHoursModel model) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Topics Studied',
                style: TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Time & Share',
                style: TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (model.topicDistribution.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No topics studied this month',
                  style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            ...model.topicDistribution.take(5).map((topic) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.topicTitle,
                            style: const TextStyle(
                              color: AppColors.textDarkPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${topic.studyHours}h (${topic.percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: (topic.percentage / 100.0).clamp(0.02, 1.0),
                        minHeight: 5,
                        backgroundColor: AppColors.darkBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWeekdayBreakdown(MonthlyStudyHoursModel model) {
    final maxWeekdayHours = model.weekdayDistribution.isEmpty
        ? 1.0
        : math.max(
            0.5,
            model.weekdayDistribution
                .map((w) => w.totalHours)
                .reduce((a, b) => math.max(a, b)),
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Habit Pattern',
                style: TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Mon – Sun',
                style: TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...model.weekdayDistribution.map((item) {
            final double factor = (item.totalHours / maxWeekdayHours).clamp(0.0, 1.0);
            final bool isHighest = item.totalHours > 0 && item.totalHours == maxWeekdayHours;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      item.dayName.substring(0, 3),
                      style: TextStyle(
                        color: isHighest ? AppColors.accent : AppColors.textDarkMuted,
                        fontSize: 11.5,
                        fontWeight: isHighest ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: factor,
                        minHeight: 6,
                        backgroundColor: AppColors.darkBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isHighest ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${item.totalHours}h',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: isHighest ? AppColors.textDarkPrimary : AppColors.textDarkMuted,
                        fontSize: 11,
                        fontWeight: isHighest ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatDateLabel(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _MetricTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
