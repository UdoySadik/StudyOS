import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../domain/dashboard_summary.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../../core/theme/app_theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roadmapsAsync = ref.watch(roadmapNotifierProvider);
    final selectedId = ref.watch(selectedRoadmapIdProvider);

    return roadmapsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (roadmaps) {
        if (roadmaps.isEmpty) {
          return _EmptyState(onCreateRoadmap: () {
            context.go('/roadmap');
          });
        }

        // Auto-select first roadmap if none selected
        if (selectedId == null && roadmaps.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedRoadmapIdProvider.notifier).state = roadmaps.first.id;
          });
        }

        final dashboardAsync = ref.watch(dashboardProvider);

        return dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (summary) {
            if (summary == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _DashboardContent(summary: summary, roadmaps: roadmaps, ref: ref);
          },
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardSummary summary;
  final List roadmaps;
  final WidgetRef ref;

  const _DashboardContent({
    required this.summary,
    required this.roadmaps,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting 👋',
                      style: const TextStyle(
                        color: AppColors.textDarkSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary.roadmapTitle,
                      style: const TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (summary.currentPhase != null && summary.currentTopic != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.play_circle_outline, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${summary.currentPhase} → ${summary.currentTopic}',
                              style: const TextStyle(
                                color: AppColors.textDarkSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                // Roadmap selector dropdown
                if (roadmaps.length > 1)
                  DropdownButton<int>(
                    value: ref.read(selectedRoadmapIdProvider),
                    dropdownColor: AppColors.darkCard,
                    style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 14),
                    underline: const SizedBox(),
                    items: roadmaps.map<DropdownMenuItem<int>>((r) {
                      return DropdownMenuItem<int>(
                        value: r.id as int,
                        child: Text(r.title as String),
                      );
                    }).toList(),
                    onChanged: (id) {
                      ref.read(selectedRoadmapIdProvider.notifier).state = id;
                    },
                  ),
              ],
            ),

            const SizedBox(height: 28),

            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_up,
                    iconColor: AppColors.primary,
                    label: 'Overall Progress',
                    value: '${summary.progress.progressPercent.toStringAsFixed(1)}%',
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: StudyProgressBar(
                        progress: summary.progress.progressPercent / 100,
                        height: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (summary.goal != null)
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer_outlined,
                      iconColor: summary.goal!.isOverdue ? AppColors.error : AppColors.warning,
                      label: 'Countdown',
                      value: summary.goal!.isOverdue
                          ? 'Overdue!'
                          : '${summary.goal!.daysRemaining} days left',
                      subtitle: 'Target: ${summary.goal!.targetDate}',
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.success,
                    label: 'Topics',
                    value: '${summary.progress.completedTopics} / ${summary.progress.totalTopics}',
                    subtitle: '${summary.progress.remainingTopics} remaining',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Today's Focus
            if (summary.todaySuggestions.isNotEmpty) ...[
              const Text(
                "Today's Focus",
                style: TextStyle(
                  color: AppColors.textDarkPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  children: summary.todaySuggestions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: i < summary.todaySuggestions.length - 1
                            ? const Border(bottom: BorderSide(color: AppColors.darkBorder))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.topicTitle,
                                  style: const TextStyle(
                                    color: AppColors.textDarkPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  s.phaseTitle,
                                  style: const TextStyle(
                                    color: AppColors.textDarkSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Phase Progress
            if (summary.phaseProgress.isNotEmpty) ...[
              const Text(
                'Phase Progress',
                style: TextStyle(
                  color: AppColors.textDarkPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  children: summary.phaseProgress.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < summary.phaseProgress.length - 1 ? 16 : 0),
                      child: StudyProgressBar(
                        progress: p.progressPercent / 100,
                        label: p.phaseTitle,
                        trailingLabel: '${p.progressPercent.toStringAsFixed(0)}%',
                        color: _phaseColor(i),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Goal details
            if (summary.goal != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Goal Details',
                style: TextStyle(
                  color: AppColors.textDarkPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _GoalStat(
                      label: 'Topics/Day Needed',
                      value: summary.goal!.topicsPerDayNeeded.toStringAsFixed(1),
                      color: AppColors.primary,
                    ),
                    _GoalStat(
                      label: 'Days Remaining',
                      value: '${summary.goal!.daysRemaining}',
                      color: AppColors.warning,
                    ),
                    _GoalStat(
                      label: 'Remaining Topics',
                      value: '${summary.progress.remainingTopics}',
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _phaseColor(int index) {
    const colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      AppColors.error,
    ];
    return colors[index % colors.length];
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final Widget? child;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textDarkMuted,
                  fontSize: 12,
                ),
              ),
            ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _GoalStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _GoalStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDarkSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateRoadmap;
  const _EmptyState({required this.onCreateRoadmap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to StudyOS',
            style: TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first roadmap to get started',
            style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: onCreateRoadmap,
            icon: const Icon(Icons.add),
            label: const Text('Create Roadmap'),
          ),
        ],
      ),
    );
  }
}
