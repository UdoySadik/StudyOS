import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/streak_provider.dart';
import '../domain/streak_model.dart';

class StreakConsistencyCard extends ConsumerWidget {
  const StreakConsistencyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(streakProvider);

    return streakAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (streak) => _buildCard(context, streak),
    );
  }

  Widget _buildCard(BuildContext context, StreakSummaryModel streak) {
    final hasStreak = streak.currentStreak > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasStreak
              ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
              : AppColors.darkBorder,
          width: 1.2,
        ),
        boxShadow: hasStreak
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row: Streak Count & Motivation ─────────────────────────
          Row(
            children: [
              // Glowing Flame Icon Badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasStreak
                        ? [const Color(0xFFF59E0B), const Color(0xFFEF4444)]
                        : [AppColors.darkSurface, AppColors.darkCard],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: hasStreak
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    hasStreak ? '🔥' : '⚡',
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          hasStreak
                              ? '${streak.currentStreak} Day Study Streak!'
                              : 'Start Your Study Streak!',
                          style: const TextStyle(
                            color: AppColors.textDarkPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (streak.isActiveToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 11, color: AppColors.success),
                                SizedBox(width: 4),
                                Text(
                                  'ACTIVE TODAY',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      streak.isActiveToday
                          ? 'You studied today! Fantastic momentum.'
                          : (hasStreak
                              ? 'Study today to keep your ${streak.currentStreak}-day streak alive!'
                              : 'Complete a study block or run the focus stopwatch to begin your streak.'),
                      style: TextStyle(
                        color: hasStreak && !streak.isActiveToday
                            ? const Color(0xFFFBBF24)
                            : AppColors.textDarkSecondary,
                        fontSize: 12.5,
                        fontWeight: hasStreak && !streak.isActiveToday
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // Streak Records Badges
              Row(
                children: [
                  _StreakStatChip(
                    icon: '🏆',
                    label: 'Best: ${streak.longestStreak} days',
                    tooltip: 'All-time longest study streak',
                  ),
                  const SizedBox(width: 10),
                  _StreakStatChip(
                    icon: '📅',
                    label: '${streak.totalActiveDays} Total Days',
                    tooltip: 'Total active study days logged',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.darkBorder, height: 1),
          const SizedBox(height: 16),

          // ── Weekly Consistency Strip ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: streak.weeklyConsistency
                .map((day) => Expanded(child: _DayConsistencyPill(day: day)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StreakStatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String tooltip;

  const _StreakStatChip({
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.sidebarBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDarkPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayConsistencyPill extends StatelessWidget {
  final DayConsistencyModel day;

  const _DayConsistencyPill({required this.day});

  @override
  Widget build(BuildContext context) {
    final parsedDate = DateTime.tryParse(day.date);
    final dayNum = parsedDate != null ? '${parsedDate.day}' : '';

    String tooltip = '${day.dayLabel}, ${day.date}';
    if (day.isActive) {
      final mins = (day.studySeconds / 60).round();
      final timeStr = mins >= 60 ? '${mins ~/ 60}h ${mins % 60}m' : '${mins}m';
      tooltip += '\nActive Day!\n• Study Time: $timeStr\n• Completed Blocks: ${day.completedBlocks}';
    } else {
      tooltip += day.isToday ? '\nToday (Not yet active)' : '\nNo study activity recorded';
    }

    Color bgColor = AppColors.sidebarBg;
    Color borderColor = AppColors.darkBorder;
    if (day.isActive) {
      bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.4);
    } else if (day.isToday) {
      borderColor = AppColors.accent.withValues(alpha: 0.5);
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: day.isToday ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              day.dayLabel,
              style: TextStyle(
                color: day.isToday ? AppColors.accent : AppColors.textDarkMuted,
                fontSize: 11,
                fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNum,
              style: TextStyle(
                color: day.isActive
                    ? AppColors.textDarkPrimary
                    : AppColors.textDarkSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            // Status Indicator Circle
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: day.isActive
                    ? const Color(0xFFF59E0B)
                    : (day.isToday
                        ? Colors.transparent
                        : AppColors.darkBorder.withValues(alpha: 0.4)),
                border: day.isToday && !day.isActive
                    ? Border.all(color: AppColors.accent, width: 1.5)
                    : null,
              ),
              child: day.isActive
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
