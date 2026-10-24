import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../../roadmap/domain/roadmap_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../timer/application/timer_provider.dart';
import '../../resources/presentation/resource_shelf_dialog.dart';
import '../../projects/application/projects_provider.dart';
import 'package:go_router/go_router.dart';

class RoadmapPage extends ConsumerStatefulWidget {
  const RoadmapPage({super.key});

  @override
  ConsumerState<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends ConsumerState<RoadmapPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCompactView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roadmapsAsync = ref.watch(roadmapNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: roadmapsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (roadmaps) {
          final filteredRoadmaps = _searchQuery.isEmpty
              ? roadmaps
              : roadmaps.where((r) =>
                  r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  (r.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
                ).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page header
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                child: Row(
                  children: [
                    const Text(
                      'Roadmap Manager',
                      style: TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    // Instant Search Filter Bar
                    Container(
                      width: 240,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search roadmaps...',
                          hintStyle: const TextStyle(color: AppColors.textDarkMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textDarkMuted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: AppColors.textDarkMuted),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // View Mode Switcher: Cards vs Compact Tree
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.view_agenda_outlined, size: 16),
                            color: !_isCompactView ? AppColors.primary : AppColors.textDarkMuted,
                            tooltip: 'Spacious Cards',
                            onPressed: () => setState(() => _isCompactView = false),
                          ),
                          Container(width: 1, height: 20, color: AppColors.darkBorder),
                          IconButton(
                            icon: const Icon(Icons.account_tree_outlined, size: 16),
                            color: _isCompactView ? AppColors.primary : AppColors.textDarkMuted,
                            tooltip: 'Compact Tree View',
                            onPressed: () => setState(() => _isCompactView = true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateRoadmapDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Roadmap'),
                    ),
                  ],
                ),
              ),

              if (roadmaps.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No roadmaps yet. Create one to get started!',
                      style: TextStyle(color: AppColors.textDarkSecondary),
                    ),
                  ),
                )
              else if (filteredRoadmaps.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppColors.textDarkMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No roadmaps matching "$_searchQuery"',
                          style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_isCompactView)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(28),
                    itemCount: filteredRoadmaps.length,
                    itemBuilder: (context, index) =>
                        _CompactRoadmapTreeCard(roadmap: filteredRoadmaps[index]),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(28),
                    itemCount: filteredRoadmaps.length,
                    itemBuilder: (context, index) =>
                        _RoadmapCard(roadmap: filteredRoadmaps[index]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showCreateRoadmapDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('New Roadmap', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: AppColors.textDarkPrimary),
              decoration: const InputDecoration(labelText: 'Title'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.textDarkPrimary),
              decoration: const InputDecoration(labelText: 'Description (optional)'),
              maxLines: 2,
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
              if (titleCtrl.text.trim().isEmpty) return;
              await ref.read(roadmapNotifierProvider.notifier).createRoadmap(
                    titleCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ── Compact Tree View Components ─────────────────────────────────────────────

class _CompactRoadmapTreeCard extends ConsumerStatefulWidget {
  final RoadmapModel roadmap;
  const _CompactRoadmapTreeCard({required this.roadmap});

  @override
  ConsumerState<_CompactRoadmapTreeCard> createState() => _CompactRoadmapTreeCardState();
}

class _CompactRoadmapTreeCardState extends ConsumerState<_CompactRoadmapTreeCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final phasesAsync = ref.watch(phaseNotifierProvider(widget.roadmap.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Roadmap header row (compact)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: AppColors.textDarkSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.folder_open, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.roadmap.title,
                      style: const TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _RoadmapActions(roadmap: widget.roadmap),
                ],
              ),
            ),
          ),
          if (_expanded)
            phasesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text('Error: $e', style: const TextStyle(color: AppColors.error, fontSize: 12)),
              ),
              data: (phases) => Column(
                children: [
                  const Divider(height: 1, color: AppColors.darkBorder),
                  ...phases.map((phase) => _CompactPhaseNode(phase: phase)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 4, 14, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _showAddPhaseDialog(context, widget.roadmap.id),
                        icon: const Icon(Icons.add, size: 13),
                        label: const Text('Add Phase', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: AppColors.textDarkSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddPhaseDialog(BuildContext context, int roadmapId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Phase', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textDarkPrimary),
          decoration: const InputDecoration(labelText: 'Phase title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(phaseNotifierProvider(roadmapId).notifier).addPhase(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CompactPhaseNode extends ConsumerStatefulWidget {
  final PhaseModel phase;
  const _CompactPhaseNode({required this.phase});

  @override
  ConsumerState<_CompactPhaseNode> createState() => _CompactPhaseNodeState();
}

class _CompactPhaseNodeState extends ConsumerState<_CompactPhaseNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicNotifierProvider(widget.phase.id));

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 14, 6),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppColors.textDarkMuted,
                  size: 15,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.subdirectory_arrow_right, color: AppColors.accent, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.phase.title,
                    style: const TextStyle(
                      color: AppColors.textDarkPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _PhaseActions(phase: widget.phase),
              ],
            ),
          ),
        ),
        if (_expanded)
          topicsAsync.when(
            loading: () => const SizedBox(),
            error: (e, _) => const SizedBox(),
            data: (topics) => Column(
              children: [
                ...topics.map((t) => _CompactTopicRow(topic: t, phaseId: widget.phase.id)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 2, 14, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _showAddTopicDialog(context, widget.phase.id),
                      icon: const Icon(Icons.add, size: 12),
                      label: const Text('Add Topic', style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: AppColors.textDarkMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showAddTopicDialog(BuildContext context, int phaseId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Topic', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textDarkPrimary),
          decoration: const InputDecoration(labelText: 'Topic title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(topicNotifierProvider(phaseId).notifier).addTopic(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CompactTopicRow extends ConsumerWidget {
  final TopicModel topic;
  final int phaseId;
  const _CompactTopicRow({required this.topic, required this.phaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 2, 14, 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              await ref
                  .read(topicNotifierProvider(phaseId).notifier)
                  .toggleComplete(topic.id, !topic.isCompleted);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: topic.isCompleted ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: topic.isCompleted ? AppColors.success : AppColors.textDarkMuted,
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: topic.isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    topic.title,
                    style: TextStyle(
                      color: topic.isCompleted ? AppColors.textDarkMuted : AppColors.textDarkPrimary,
                      fontSize: 12,
                      decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _TopicStudyBadge(topicId: topic.id),
              ],
            ),
          ),
          _TopicActions(topic: topic, phaseId: phaseId),
        ],
      ),
    );
  }
}

// ── Roadmap Card ──────────────────────────────────────────────────────────────

class _RoadmapCard extends ConsumerStatefulWidget {
  final RoadmapModel roadmap;
  const _RoadmapCard({required this.roadmap});

  @override
  ConsumerState<_RoadmapCard> createState() => _RoadmapCardState();
}

class _RoadmapCardState extends ConsumerState<_RoadmapCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final phasesAsync = ref.watch(phaseNotifierProvider(widget.roadmap.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          // Roadmap header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: AppColors.textDarkSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.map_outlined, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.roadmap.title,
                      style: const TextStyle(
                        color: AppColors.textDarkPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _RoadmapActions(roadmap: widget.roadmap),
                ],
              ),
            ),
          ),

          // Phases
          if (_expanded)
            phasesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (e, _) => Text('Error: $e'),
              data: (phases) => Column(
                children: [
                  const Divider(height: 1, color: AppColors.darkBorder),
                  ...phases.map((phase) => _PhaseTile(phase: phase)),
                  // Add phase button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: TextButton.icon(
                      onPressed: () => _showAddPhaseDialog(context, widget.roadmap.id),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add Phase'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textDarkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAddPhaseDialog(BuildContext context, int roadmapId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Phase', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textDarkPrimary),
          decoration: const InputDecoration(labelText: 'Phase title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(phaseNotifierProvider(roadmapId).notifier).addPhase(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ── Phase Tile ────────────────────────────────────────────────────────────────

class _PhaseTile extends ConsumerStatefulWidget {
  final PhaseModel phase;
  const _PhaseTile({required this.phase});

  @override
  ConsumerState<_PhaseTile> createState() => _PhaseTileState();
}

class _PhaseTileState extends ConsumerState<_PhaseTile> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicNotifierProvider(widget.phase.id));

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 10, 16, 10),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppColors.textDarkMuted,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.layers_outlined, color: AppColors.accent, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.phase.title,
                    style: const TextStyle(
                      color: AppColors.textDarkPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _PhaseActions(phase: widget.phase),
              ],
            ),
          ),
        ),
        if (_expanded)
          topicsAsync.when(
            loading: () => const SizedBox(),
            error: (e, _) => Text('Error: $e'),
            data: (topics) => Column(
              children: [
                ...topics.map((t) => _TopicTile(topic: t, phaseId: widget.phase.id)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(44, 4, 16, 8),
                  child: TextButton.icon(
                    onPressed: () => _showAddTopicDialog(context, widget.phase.id),
                    icon: const Icon(Icons.add, size: 13),
                    label: const Text('Add Topic', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textDarkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1, color: AppColors.darkBorder, indent: 28),
      ],
    );
  }

  void _showAddTopicDialog(BuildContext context, int phaseId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Topic', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textDarkPrimary),
          decoration: const InputDecoration(labelText: 'Topic title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(topicNotifierProvider(phaseId).notifier).addTopic(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ── Topic Tile ────────────────────────────────────────────────────────────────

class _TopicTile extends ConsumerStatefulWidget {
  final TopicModel topic;
  final int phaseId;
  const _TopicTile({required this.topic, required this.phaseId});

  @override
  ConsumerState<_TopicTile> createState() => _TopicTileState();
}

class _TopicTileState extends ConsumerState<_TopicTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final topic = widget.topic;
    final subtopicsAsync = _expanded ? ref.watch(subtopicNotifierProvider(topic.id)) : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(44, 6, 16, 6),
          child: Row(
            children: [
              // Expand arrow
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Icon(
                  _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: AppColors.textDarkMuted,
                  size: 15,
                ),
              ),
              const SizedBox(width: 6),
              // Completion checkbox
              GestureDetector(
                onTap: () async {
                  await ref
                      .read(topicNotifierProvider(widget.phaseId).notifier)
                      .toggleComplete(topic.id, !topic.isCompleted);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: topic.isCompleted ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: topic.isCompleted ? AppColors.success : AppColors.textDarkMuted,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: topic.isCompleted
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        topic.title,
                        style: TextStyle(
                          color: topic.isCompleted
                              ? AppColors.textDarkMuted
                              : AppColors.textDarkPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          decoration: topic.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    _TopicStudyBadge(topicId: topic.id),
                  ],
                ),
              ),
              _TopicActions(topic: topic, phaseId: widget.phaseId),
            ],
          ),
        ),
        // Subtopics
        if (_expanded && subtopicsAsync != null)
          subtopicsAsync.when(
            loading: () => const SizedBox(),
            error: (e, _) => Text('Error: $e'),
            data: (subtopics) => Column(
              children: [
                ...subtopics.map((s) => _SubtopicTile(subtopic: s, topicId: topic.id)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 2, 16, 4),
                  child: TextButton.icon(
                    onPressed: () => _showAddSubtopicDialog(context, topic.id),
                    icon: const Icon(Icons.add, size: 12),
                    label: const Text('Add Subtopic', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textDarkMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showAddSubtopicDialog(BuildContext context, int topicId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Add Subtopic', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textDarkPrimary),
          decoration: const InputDecoration(labelText: 'Subtopic title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(subtopicNotifierProvider(topicId).notifier).addSubtopic(ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ── Subtopic Tile ─────────────────────────────────────────────────────────────

class _SubtopicTile extends ConsumerWidget {
  final SubtopicModel subtopic;
  final int topicId;
  const _SubtopicTile({required this.subtopic, required this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 4, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              await ref
                  .read(subtopicNotifierProvider(topicId).notifier)
                  .toggleComplete(subtopic.id, !subtopic.isCompleted);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: subtopic.isCompleted ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: subtopic.isCompleted ? AppColors.success : AppColors.textDarkMuted,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '• ${subtopic.title}',
              style: TextStyle(
                color: subtopic.isCompleted ? AppColors.textDarkMuted : AppColors.textDarkSecondary,
                fontSize: 12,
                decoration: subtopic.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 14),
            color: AppColors.textDarkMuted,
            onPressed: () async {
              await ref.read(subtopicNotifierProvider(topicId).notifier).deleteSubtopic(subtopic.id);
            },
          ),
        ],
      ),
    );
  }
}

// ── Action widgets ────────────────────────────────────────────────────────────

class _RoadmapActions extends ConsumerWidget {
  final RoadmapModel roadmap;
  const _RoadmapActions({required this.roadmap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 16),
          color: AppColors.textDarkSecondary,
          onPressed: () => _showEditDialog(context, ref),
          tooltip: 'Edit',
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 16),
          color: AppColors.error,
          onPressed: () => _confirmDelete(context, ref),
          tooltip: 'Delete',
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: roadmap.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Edit Roadmap', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textDarkPrimary),
          decoration: const InputDecoration(labelText: 'Title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(roadmapNotifierProvider.notifier).updateRoadmap(roadmap.id, ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Roadmap?', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: Text(
          'This will permanently delete "${roadmap.title}" and all its phases, topics, and notes.',
          style: const TextStyle(color: AppColors.textDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(roadmapNotifierProvider.notifier).deleteRoadmap(roadmap.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PhaseActions extends ConsumerWidget {
  final PhaseModel phase;
  const _PhaseActions({required this.phase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 14),
          color: AppColors.textDarkMuted,
          onPressed: () => _showEditDialog(context, ref),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 14),
          color: AppColors.error.withValues(alpha: 0.7),
          onPressed: () async {
            await ref.read(phaseNotifierProvider(phase.roadmapId).notifier).deletePhase(phase.id);
          },
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: phase.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Edit Phase', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textDarkPrimary),
          decoration: const InputDecoration(labelText: 'Phase title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(phaseNotifierProvider(phase.roadmapId).notifier).updatePhase(phase.id, ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TopicActions extends ConsumerWidget {
  final TopicModel topic;
  final int phaseId;
  const _TopicActions({required this.topic, required this.phaseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.timer_outlined, size: 14),
          color: AppColors.accent,
          tooltip: 'Start Study Stopwatch',
          onPressed: () {
            ref.read(studyTimerProvider.notifier).startTimer(topic.id, topic.title);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Study timer started for "${topic.title}"!'),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.shelves, size: 14),
          color: const Color(0xFFF59E0B),
          tooltip: 'Learning Resource Shelf (Books, Courses, PDFs)',
          onPressed: () {
            ResourceShelfDialog.show(context, topic.id, topic.title);
          },
        ),
        IconButton(
          icon: const Icon(Icons.code_rounded, size: 14),
          color: const Color(0xFF6366F1),
          tooltip: 'Practice Projects',
          onPressed: () {
            ref.read(projectSearchQueryProvider.notifier).state = topic.title;
            context.go('/projects');
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 13),
          color: AppColors.textDarkMuted,
          onPressed: () => _showEditDialog(context, ref),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 13),
          color: AppColors.error.withValues(alpha: 0.6),
          onPressed: () async {
            await ref.read(topicNotifierProvider(phaseId).notifier).deleteTopic(topic.id);
          },
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: topic.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Edit Topic', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: AppColors.textDarkPrimary),
          decoration: const InputDecoration(labelText: 'Topic title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref.read(topicNotifierProvider(phaseId).notifier).updateTopic(topic.id, ctrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _TopicStudyBadge extends ConsumerWidget {
  final int topicId;
  const _TopicStudyBadge({required this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(topicStudyStatsProvider(topicId));
    return statsAsync.maybeWhen(
      data: (stats) {
        if (stats.totalSeconds == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer, size: 10, color: AppColors.primary),
              const SizedBox(width: 3),
              Text(
                stats.formattedDuration,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
