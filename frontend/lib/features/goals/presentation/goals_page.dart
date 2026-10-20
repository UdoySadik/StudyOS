import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../dashboard/domain/dashboard_summary.dart';
import '../application/goals_provider.dart';
import '../domain/goal_model.dart';
import '../../../core/theme/app_theme.dart';

class GoalsPage extends ConsumerStatefulWidget {
  const GoalsPage({super.key});

  @override
  ConsumerState<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends ConsumerState<GoalsPage> {
  Future<void> _selectDate(BuildContext context, DateTime? initialDate, Function(String) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.darkCard,
              onSurface: AppColors.textDarkPrimary,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: AppColors.darkBg),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      onDateSelected(formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoadmapId = ref.watch(selectedRoadmapIdProvider);
    final goalsAsync = ref.watch(goalNotifierProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goal Manager',
              style: TextStyle(
                color: AppColors.textDarkPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set a target completion date to calculate remaining days and required study pace.',
              style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),
            if (selectedRoadmapId == null)
              const Expanded(
                child: Center(
                  child: Text(
                    'Please select or create a roadmap first to set goals.',
                    style: TextStyle(color: AppColors.textDarkSecondary),
                  ),
                ),
              )
            else
              Expanded(
                child: goalsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (goals) {
                    final currentGoal = goals.isNotEmpty ? goals.first : null;

                    return dashboardAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                      data: (summary) {
                        if (summary == null) return const SizedBox();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (currentGoal == null) ...[
                              _buildNoGoalCard(context)
                            ] else ...[
                              _buildActiveGoalCard(context, currentGoal, summary),
                              const SizedBox(height: 24),
                              _buildStatisticsPanel(summary),
                            ]
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGoalCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, size: 48, color: AppColors.textDarkMuted),
          const SizedBox(height: 16),
          const Text(
            'No Target Date Set',
            style: TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep yourself motivated and on schedule by setting your completion goal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _selectDate(context, null, (dateStr) {
              ref.read(goalNotifierProvider.notifier).setGoal(dateStr).then((_) {
                ref.invalidate(dashboardProvider);
              });
            }),
            icon: const Icon(Icons.calendar_today, size: 16),
            label: const Text('Set Target Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGoalCard(BuildContext context, GoalModel goal, DashboardSummary summary) {
    final parsedDate = DateTime.tryParse(goal.targetDate);
    final formattedDate = parsedDate != null ? DateFormat('MMMM d, yyyy').format(parsedDate) : goal.targetDate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
        gradient: LinearGradient(
          colors: [AppColors.darkCard, AppColors.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flag, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Completion Date',
                        style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: AppColors.textDarkPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _selectDate(context, parsedDate, (dateStr) {
                      ref.read(goalNotifierProvider.notifier).updateGoal(goal.id, dateStr).then((_) {
                        ref.invalidate(dashboardProvider);
                      });
                    }),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Change Date'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.textDarkSecondary),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.error,
                    onPressed: () {
                      ref.read(goalNotifierProvider.notifier).deleteGoal(goal.id).then((_) {
                        ref.invalidate(dashboardProvider);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          if (summary.goal != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildGoalDetailTile(
                    'Days Remaining',
                    '${summary.goal!.daysRemaining}',
                    Icons.schedule,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGoalDetailTile(
                    'Pace Needed',
                    '${summary.goal!.topicsPerDayNeeded.toStringAsFixed(2)} topics/day',
                    Icons.trending_up,
                    AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalDetailTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textDarkPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel(DashboardSummary summary) {
    final remainingTopics = summary.progress.remainingTopics;
    final completedTopics = summary.progress.completedTopics;
    final totalTopics = summary.progress.totalTopics;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Automatic Calculation & Progress Summary',
              style: TextStyle(
                color: AppColors.textDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildStatSummaryRow('Topics Completed', '$completedTopics / $totalTopics'),
            const Divider(color: AppColors.darkBorder, height: 24),
            _buildStatSummaryRow('Remaining Topics', '$remainingTopics'),
            const Divider(color: AppColors.darkBorder, height: 24),
            if (summary.goal != null) ...[
              _buildStatSummaryRow('Remaining Days', '${summary.goal!.daysRemaining} Days'),
              const Divider(color: AppColors.darkBorder, height: 24),
              _buildStatSummaryRow(
                'Estimated Pace',
                '${summary.goal!.topicsPerDayNeeded.toStringAsFixed(2)} topics every day',
              ),
            ] else ...[
              _buildStatSummaryRow('Remaining Days', 'Not Set'),
              const Divider(color: AppColors.darkBorder, height: 24),
              _buildStatSummaryRow('Estimated Pace', 'Not Set'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDarkPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
