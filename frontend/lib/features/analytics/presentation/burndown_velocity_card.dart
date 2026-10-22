import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/burndown_provider.dart';
import '../domain/burndown_model.dart';

class BurndownVelocityCard extends ConsumerWidget {
  final int roadmapId;

  const BurndownVelocityCard({super.key, required this.roadmapId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final burndownAsync = ref.watch(burndownProvider(roadmapId));

    return burndownAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (model) => _buildCard(context, model),
    );
  }

  Widget _buildCard(BuildContext context, RoadmapBurndownModel model) {
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
          // ── Header Row ───────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.analytics_outlined, color: AppColors.primaryLight, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phase Burndown & Learning Velocity',
                      style: TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Completion progress per phase and daily velocity toward deadline',
                      style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              _buildStatusPill(model),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.darkBorder, height: 1),
          const SizedBox(height: 20),

          // ── Two Column Master/Detail Layout ───────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Phase Burndown Progress List (flex: 6)
              Expanded(
                flex: 6,
                child: _buildPhaseBurndownSection(model),
              ),
              const SizedBox(width: 24),
              // Right: Velocity Gauges & 7-Day Bar Chart (flex: 5)
              Expanded(
                flex: 5,
                child: _buildVelocitySection(model),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(RoadmapBurndownModel model) {
    Color color;
    Color bgColor;

    switch (model.status) {
      case 'ahead':
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
        break;
      case 'on_track':
        color = const Color(0xFF06B6D4);
        bgColor = const Color(0xFF06B6D4).withValues(alpha: 0.15);
        break;
      case 'behind':
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        break;
      case 'completed':
        color = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.15);
        break;
      default:
        color = AppColors.textDarkSecondary;
        bgColor = AppColors.darkCardHover;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        model.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPhaseBurndownSection(RoadmapBurndownModel model) {
    if (model.phases.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'No phases defined yet in this roadmap.',
          style: TextStyle(color: AppColors.textDarkMuted, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Phase Breakdown',
              style: TextStyle(
                color: AppColors.textDarkSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              '${model.completedTopics}/${model.totalTopics} Topics (${model.progressPercent.toStringAsFixed(1)}%)',
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Phase progress cards
        ...model.phases.map((phase) {
          final isDone = phase.remainingTopics == 0 && phase.totalTopics > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.sidebarBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.darkBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isDone)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.check_circle, size: 14, color: AppColors.success),
                      ),
                    Expanded(
                      child: Text(
                        '${phase.orderIndex + 1}. ${phase.phaseTitle}',
                        style: TextStyle(
                          color: isDone ? AppColors.textDarkMuted : AppColors.textDarkPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${phase.completedTopics}/${phase.totalTopics} done',
                      style: TextStyle(
                        color: isDone ? AppColors.success : AppColors.textDarkMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: phase.totalTopics > 0 ? (phase.completedTopics / phase.totalTopics) : 0.0,
                    minHeight: 5,
                    backgroundColor: AppColors.darkBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDone ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
                if (!isDone && phase.estimatedDaysToComplete != null && phase.estimatedDaysToComplete! > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    '~${phase.estimatedDaysToComplete!.toStringAsFixed(1)} days to complete at current pace',
                    style: const TextStyle(
                      color: AppColors.textDarkMuted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVelocitySection(RoadmapBurndownModel model) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning Velocity & Trajectory',
          style: TextStyle(
            color: AppColors.textDarkSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),

        // Velocity Stats Triplets
        Row(
          children: [
            Expanded(
              child: _VelocityMetricBox(
                label: 'Current Pace',
                value: '${model.currentVelocity7d}',
                unit: 'topics/day',
                subtitle: 'Past 7-day average',
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VelocityMetricBox(
                label: 'Required Pace',
                value: model.requiredVelocity > 0 ? '${model.requiredVelocity}' : '—',
                unit: 'topics/day',
                subtitle: model.daysRemaining != null ? 'For ${model.daysRemaining}d deadline' : 'No deadline',
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _VelocityMetricBox(
                label: 'Projected Finish',
                value: model.projectedCompletionDate != null
                    ? _formatShortDate(model.projectedCompletionDate!)
                    : '—',
                unit: '',
                subtitle: model.currentVelocity7d > 0 ? 'At current rate' : 'Needs activity',
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 7-Day Velocity Bar Chart
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.sidebarBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '7-Day Topics Completed',
                    style: TextStyle(color: AppColors.textDarkMuted, fontSize: 11.5, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Topics / Day',
                    style: TextStyle(color: AppColors.textDarkMuted, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: model.recentVelocity.map((day) {
                    final count = day.topicsCompleted;
                    final maxCount = math.max(1, model.recentVelocity.map((d) => d.topicsCompleted).reduce(math.max));
                    final heightFactor = (count / maxCount).clamp(0.08, 1.0);

                    return Expanded(
                      child: Tooltip(
                        message: '${day.dayLabel}, ${day.date}\n• $count topics completed\n• ${(day.studySeconds / 3600).toStringAsFixed(1)}h studied',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (count > 0)
                              Text(
                                '$count',
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              const SizedBox(height: 12),
                            const SizedBox(height: 4),
                            SizedBox(
                              height: 40,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: 14,
                                  height: math.max(4.0, 40.0 * heightFactor),
                                  decoration: BoxDecoration(
                                    gradient: count > 0
                                        ? const LinearGradient(
                                            colors: [AppColors.primary, AppColors.accent],
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                          )
                                        : null,
                                    color: count > 0 ? null : AppColors.darkCardHover,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              day.dayLabel.substring(0, 1),
                              style: const TextStyle(
                                color: AppColors.textDarkMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatShortDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _VelocityMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String subtitle;
  final Color color;

  const _VelocityMetricBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sidebarBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    unit,
                    style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 9.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
