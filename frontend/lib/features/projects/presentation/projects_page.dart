import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../application/projects_provider.dart';
import '../domain/project_model.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProjectsAsync = ref.watch(filteredProjectsProvider);
    final stats = ref.watch(projectStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref),
              const SizedBox(height: 20),
              _buildMetricsRow(stats),
              const SizedBox(height: 20),
              _buildFilterAndSearchStrip(context, ref, stats),
              const SizedBox(height: 16),
              Expanded(
                child: filteredProjectsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Error loading projects: $err',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                  data: (projects) {
                    if (projects.isEmpty) {
                      return _buildEmptyState(context, ref);
                    }
                    return ListView.separated(
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (ctx, idx) => _ProjectCard(project: projects[idx]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Practice Project Tracker',
                style: TextStyle(
                  color: AppColors.textDarkPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Track practical implementations, repositories, and portfolio work linked to study topics',
                style: TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          key: const Key('new_project_button'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'New Project',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 2,
          ),
          onPressed: () => _showProjectDialog(context, ref),
        ),
      ],
    );
  }

  Widget _buildMetricsRow(ProjectStats stats) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Total Projects',
            value: '${stats.total}',
            icon: Icons.code_rounded,
            accentColor: AppColors.primaryLight,
            subtitle: 'Portfolio items',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            title: 'In Progress',
            value: '${stats.inProgress}',
            icon: Icons.trending_up_rounded,
            accentColor: const Color(0xFF3B82F6),
            subtitle: 'Active builds',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            title: 'Completed',
            value: '${stats.completed}',
            icon: Icons.verified_rounded,
            accentColor: const Color(0xFF10B981),
            subtitle: 'Shipped & verified',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            title: 'Completion Rate',
            value: '${(stats.completionRate * 100).toStringAsFixed(0)}%',
            icon: Icons.pie_chart_rounded,
            accentColor: const Color(0xFF8B5CF6),
            subtitle: '${stats.completed} of ${stats.total} projects',
            progress: stats.completionRate,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndSearchStrip(
    BuildContext context,
    WidgetRef ref,
    ProjectStats stats,
  ) {
    final currentStatus = ref.watch(projectStatusFilterProvider);
    final currentRoadmap = ref.watch(projectRoadmapFilterProvider);
    final roadmapsAsync = ref.watch(roadmapsProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          // Search box
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 38,
              child: TextField(
                key: const Key('project_search_field'),
                style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search projects, tech stack, roadmap...',
                  hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textDarkSecondary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  filled: true,
                  fillColor: AppColors.darkBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (val) {
                  ref.read(projectSearchQueryProvider.notifier).state = val;
                },
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Status tabs
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusFilterChip(
                    label: 'All',
                    count: stats.total,
                    isSelected: currentStatus == null,
                    onSelected: () => ref.read(projectStatusFilterProvider.notifier).state = null,
                  ),
                  const SizedBox(width: 6),
                  _StatusFilterChip(
                    label: 'In Progress',
                    count: stats.inProgress,
                    isSelected: currentStatus == 'in_progress',
                    color: const Color(0xFF3B82F6),
                    onSelected: () => ref.read(projectStatusFilterProvider.notifier).state = 'in_progress',
                  ),
                  const SizedBox(width: 6),
                  _StatusFilterChip(
                    label: 'Completed',
                    count: stats.completed,
                    isSelected: currentStatus == 'completed',
                    color: const Color(0xFF10B981),
                    onSelected: () => ref.read(projectStatusFilterProvider.notifier).state = 'completed',
                  ),
                  const SizedBox(width: 6),
                  _StatusFilterChip(
                    label: 'Not Started',
                    count: stats.notStarted,
                    isSelected: currentStatus == 'not_started',
                    color: const Color(0xFF9494B0),
                    onSelected: () => ref.read(projectStatusFilterProvider.notifier).state = 'not_started',
                  ),
                  const SizedBox(width: 6),
                  _StatusFilterChip(
                    label: 'On Hold',
                    count: stats.onHold,
                    isSelected: currentStatus == 'on_hold',
                    color: const Color(0xFFF59E0B),
                    onSelected: () => ref.read(projectStatusFilterProvider.notifier).state = 'on_hold',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Roadmap filter dropdown
          roadmapsAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (roadmaps) {
              return Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.darkBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: currentRoadmap,
                    dropdownColor: AppColors.darkCard,
                    style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 12.5),
                    hint: const Text(
                      'All Roadmaps',
                      style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12.5),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All Roadmaps'),
                      ),
                      ...roadmaps.map((r) => DropdownMenuItem<int?>(
                            value: r.id,
                            child: Text(r.title),
                          )),
                    ],
                    onChanged: (val) {
                      ref.read(projectRoadmapFilterProvider.notifier).state = val;
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.code_rounded,
              size: 48,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No practice projects found',
            style: TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create projects to link practical code repositories to your study topics.',
            style: TextStyle(
              color: AppColors.textDarkSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Practice Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showProjectDialog(context, ref),
          ),
        ],
      ),
    );
  }

  static void _showProjectDialog(
    BuildContext context,
    WidgetRef ref, {
    ProjectModel? project,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _ProjectFormDialog(project: project),
    );
  }
}

// ── Metric Card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String subtitle;
  final double? progress;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.subtitle,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.darkBorder,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textDarkMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Filter Chip ───────────────────────────────────────────────────────

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onSelected;

  const _StatusFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryLight;

    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? effectiveColor : AppColors.darkBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textDarkPrimary : AppColors.textDarkSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? effectiveColor.withValues(alpha: 0.25)
                    : AppColors.darkBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textDarkMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Project Card ────────────────────────────────────────────────────────────

class _ProjectCard extends ConsumerWidget {
  final ProjectModel project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techList = project.techStackList;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: badges and menu
          Row(
            children: [
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: project.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: project.statusColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: project.statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      project.statusLabel,
                      style: TextStyle(
                        color: project.statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Difficulty Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: project.difficultyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  project.difficultyLabel.toUpperCase(),
                  style: TextStyle(
                    color: project.difficultyColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Roadmap Badge
              if (project.roadmapTitle != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_outlined, size: 11, color: AppColors.primaryLight),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            project.roadmapTitle!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (project.topicTitle != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tag, size: 11, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            project.topicTitle!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),

              // Popup Menu (Edit, Delete, Status Change)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16, color: AppColors.textDarkMuted),
                color: AppColors.darkCard,
                onSelected: (val) {
                  if (val == 'edit') {
                    showDialog(
                      context: context,
                      builder: (ctx) => _ProjectFormDialog(project: project),
                    );
                  } else if (val == 'delete') {
                    _confirmDelete(context, ref);
                  } else if (val.startsWith('status_')) {
                    final newStatus = val.replaceFirst('status_', '');
                    ref.read(projectsListProvider.notifier).updateStatus(project.id, newStatus);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 15, color: AppColors.textDarkSecondary),
                        SizedBox(width: 8),
                        Text('Edit Project', style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'status_in_progress',
                    child: Text('Set In Progress', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12.5)),
                  ),
                  const PopupMenuItem(
                    value: 'status_completed',
                    child: Text('Set Completed', style: TextStyle(color: Color(0xFF10B981), fontSize: 12.5)),
                  ),
                  const PopupMenuItem(
                    value: 'status_on_hold',
                    child: Text('Set On Hold', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12.5)),
                  ),
                  const PopupMenuItem(
                    value: 'status_not_started',
                    child: Text('Set Not Started', style: TextStyle(color: Color(0xFF9494B0), fontSize: 12.5)),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 15, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Project Title
          Text(
            project.title,
            style: const TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (project.description != null && project.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              project.description!,
              style: const TextStyle(
                color: AppColors.textDarkSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Tech stack chips
          if (techList.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: techList.map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Text(
                    tech,
                    style: const TextStyle(
                      color: AppColors.textDarkSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Footer Action Links Row
          Row(
            children: [
              // GitHub button
              if (project.githubUrl != null && project.githubUrl!.isNotEmpty)
                _LinkActionButton(
                  key: Key('project_github_btn_${project.id}'),
                  icon: Icons.code_rounded,
                  label: 'GitHub Repo',
                  url: project.githubUrl!,
                  color: const Color(0xFF8B5CF6),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.code_off, size: 13, color: AppColors.textDarkMuted),
                      SizedBox(width: 5),
                      Text(
                        'No Repo Linked',
                        style: TextStyle(color: AppColors.textDarkMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 10),

              // Live URL button
              if (project.liveUrl != null && project.liveUrl!.isNotEmpty) ...[
                _LinkActionButton(
                  key: Key('project_live_btn_${project.id}'),
                  icon: Icons.rocket_launch_outlined,
                  label: 'Live Demo',
                  url: project.liveUrl!,
                  color: const Color(0xFF06B6D4),
                ),
                const SizedBox(width: 10),
              ],

              const Spacer(),

              // Quick status complete toggle button
              InkWell(
                key: Key('project_toggle_status_${project.id}'),
                onTap: () async {
                  final nextStatus = project.isCompleted ? 'in_progress' : 'completed';
                  await ref
                      .read(projectsListProvider.notifier)
                      .updateStatus(project.id, nextStatus);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: project.isCompleted
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : AppColors.darkBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: project.isCompleted
                          ? const Color(0xFF10B981)
                          : AppColors.darkBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        project.isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                        size: 14,
                        color: project.isCompleted
                            ? const Color(0xFF10B981)
                            : AppColors.textDarkSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        project.isCompleted ? 'Completed' : 'Mark Complete',
                        style: TextStyle(
                          color: project.isCompleted
                              ? const Color(0xFF10B981)
                              : AppColors.textDarkSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Project', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: Text(
          'Are you sure you want to delete "${project.title}"?',
          style: const TextStyle(color: AppColors.textDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(projectsListProvider.notifier).deleteProject(project.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Link Action Button ──────────────────────────────────────────────────────

class _LinkActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;

  const _LinkActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.darkCard,
            content: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Copied $label link: $url',
                    style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.copy_rounded, size: 11, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

// ── Project Form Dialog ─────────────────────────────────────────────────────

class _ProjectFormDialog extends ConsumerStatefulWidget {
  final ProjectModel? project;
  const _ProjectFormDialog({this.project});

  @override
  ConsumerState<_ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends ConsumerState<_ProjectFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _githubCtrl;
  late final TextEditingController _liveCtrl;
  late final TextEditingController _techCtrl;

  int? _selectedRoadmapId;
  int? _selectedTopicId;
  String _selectedDifficulty = 'medium';
  String _selectedStatus = 'not_started';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _githubCtrl = TextEditingController(text: p?.githubUrl ?? '');
    _liveCtrl = TextEditingController(text: p?.liveUrl ?? '');
    _techCtrl = TextEditingController(text: p?.techStack ?? '');
    _selectedRoadmapId = p?.roadmapId;
    _selectedTopicId = p?.topicId;
    _selectedDifficulty = p?.difficulty ?? 'medium';
    _selectedStatus = p?.status ?? 'not_started';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _githubCtrl.dispose();
    _liveCtrl.dispose();
    _techCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roadmapsAsync = ref.watch(roadmapsProvider);
    final isEditing = widget.project != null;

    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Practice Project' : 'Create Practice Project',
                      style: const TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: AppColors.textDarkSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppColors.darkBorder),
                const SizedBox(height: 8),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Roadmap selector
                        const Text(
                          'Linked Roadmap *',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        roadmapsAsync.when(
                          loading: () => const LinearProgressIndicator(color: AppColors.primary),
                          error: (e, _) => Text('Error loading roadmaps: $e', style: const TextStyle(color: AppColors.error)),
                          data: (roadmaps) {
                            if (roadmaps.isEmpty) {
                              return const Text('No roadmaps available. Create one first.', style: TextStyle(color: AppColors.warning));
                            }
                            if (_selectedRoadmapId == null && roadmaps.isNotEmpty) {
                              _selectedRoadmapId = roadmaps.first.id;
                            }
                            return DropdownButtonFormField<int>(
                              key: const Key('project_roadmap_dropdown'),
                              initialValue: _selectedRoadmapId,
                              dropdownColor: AppColors.darkCard,
                              style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: roadmaps
                                  .map((r) => DropdownMenuItem(
                                        value: r.id,
                                        child: Text(r.title),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedRoadmapId = val;
                                  _selectedTopicId = null;
                                });
                              },
                              validator: (val) => val == null ? 'Please select a roadmap' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Project Title
                        const Text(
                          'Project Title *',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('project_title_input'),
                          controller: _titleCtrl,
                          style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Distributed Key-Value Store in Go',
                            isDense: true,
                          ),
                          validator: (val) =>
                              (val == null || val.trim().isEmpty) ? 'Project title is required' : null,
                        ),
                        const SizedBox(height: 14),

                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('project_desc_input'),
                          controller: _descCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Summary of the system architecture, features, and core learning takeaways',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Tech Stack
                        const Text(
                          'Tech Stack (comma separated)',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('project_tech_input'),
                          controller: _techCtrl,
                          style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'e.g. Go, Raft, gRPC, Docker, PostgreSQL',
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Difficulty & Status Pickers
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Difficulty
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Difficulty',
                                    style: TextStyle(
                                      color: AppColors.textDarkSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _buildChoiceChip('Beginner', 'beginner', const Color(0xFF10B981)),
                                      _buildChoiceChip('Medium', 'medium', const Color(0xFFF59E0B)),
                                      _buildChoiceChip('Advanced', 'advanced', const Color(0xFFEF4444)),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Status
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Status',
                                    style: TextStyle(
                                      color: AppColors.textDarkSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildStatusChip('Not Started', 'not_started', const Color(0xFF9494B0)),
                                      _buildStatusChip('In Progress', 'in_progress', const Color(0xFF3B82F6)),
                                      _buildStatusChip('Completed', 'completed', const Color(0xFF10B981)),
                                      _buildStatusChip('On Hold', 'on_hold', const Color(0xFFF59E0B)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // GitHub URL
                        const Text(
                          'GitHub Repository Link',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('project_github_input'),
                          controller: _githubCtrl,
                          style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'https://github.com/username/project-repo',
                            prefixIcon: Icon(Icons.code_rounded, size: 18, color: Color(0xFF8B5CF6)),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Live Demo URL
                        const Text(
                          'Live Demo / Documentation Link (Optional)',
                          style: TextStyle(
                            color: AppColors.textDarkSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          key: const Key('project_live_input'),
                          controller: _liveCtrl,
                          style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'https://demo.project.dev',
                            prefixIcon: Icon(Icons.rocket_launch_outlined, size: 18, color: Color(0xFF06B6D4)),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.darkBorder),
                const SizedBox(height: 16),

                // Footer Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      key: const Key('project_submit_btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _isSaving ? null : _saveProject,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Create Project'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value, Color color) {
    final isSelected = _selectedDifficulty == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.25),
      backgroundColor: AppColors.darkCard,
      side: BorderSide(color: isSelected ? color : AppColors.darkBorder),
      labelStyle: TextStyle(
        color: isSelected ? color : AppColors.textDarkSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedDifficulty = value);
      },
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.25),
      backgroundColor: AppColors.darkCard,
      side: BorderSide(color: isSelected ? color : AppColors.darkBorder),
      labelStyle: TextStyle(
        color: isSelected ? color : AppColors.textDarkSecondary,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedStatus = value);
      },
    );
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoadmapId == null) return;

    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(projectsListProvider.notifier);
      if (widget.project != null) {
        await notifier.updateProject(
          widget.project!.id,
          roadmapId: _selectedRoadmapId,
          topicId: _selectedTopicId,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          githubUrl: _githubCtrl.text,
          liveUrl: _liveCtrl.text,
          status: _selectedStatus,
          difficulty: _selectedDifficulty,
          techStack: _techCtrl.text,
        );
      } else {
        await notifier.createProject(
          roadmapId: _selectedRoadmapId!,
          topicId: _selectedTopicId,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          githubUrl: _githubCtrl.text,
          liveUrl: _liveCtrl.text,
          status: _selectedStatus,
          difficulty: _selectedDifficulty,
          techStack: _techCtrl.text,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to save project: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
