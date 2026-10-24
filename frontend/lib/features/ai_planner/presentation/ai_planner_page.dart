import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../application/ai_planner_provider.dart';
import '../domain/study_plan_model.dart';

class AIPlannerPage extends ConsumerStatefulWidget {
  const AIPlannerPage({super.key});

  @override
  ConsumerState<AIPlannerPage> createState() => _AIPlannerPageState();
}

class _AIPlannerPageState extends ConsumerState<AIPlannerPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _constraintsCtrl = TextEditingController();

  String _proficiency = 'intermediate';
  int _targetWeeks = 4;
  int _hoursPerWeek = 10;
  String _focusArea = 'Practical Projects & Architecture';
  int? _selectedRoadmapId;
  bool _isGenerating = false;
  bool _isImporting = false;

  final List<String> _quickSuggestions = [
    'Rust Systems Programming',
    'Distributed Systems & Raft',
    'Kubernetes & Cloud Native',
    'Compiler Design & LLVM',
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _constraintsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ollamaAsync = ref.watch(ollamaStatusProvider);
    final plansAsync = ref.watch(studyPlansListProvider);
    final selectedPlan = ref.watch(selectedPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 14),
              _buildOllamaStatusStrip(ollamaAsync),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Panel: Generator Form & Saved Plans History
                    SizedBox(
                      width: 400,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildGeneratorCard(),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            flex: 4,
                            child: _buildSavedPlansCard(plansAsync, selectedPlan),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Right Panel: Selected Plan Viewer & Markdown Preview
                    Expanded(
                      child: _buildPlanViewer(selectedPlan),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Offline LLM Study Planner',
                    style: TextStyle(
                      color: AppColors.textDarkPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Generate personalized study syllabi, milestones & projects via local Ollama models with offline fallback',
                style: TextStyle(
                  color: AppColors.textDarkSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOllamaStatusStrip(AsyncValue<OllamaStatusModel> ollamaAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: ollamaAsync.when(
        loading: () => const Row(
          children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            SizedBox(width: 8),
            Text('Checking local Ollama connection...', style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12)),
          ],
        ),
        error: (_, __) => _buildOfflineNotice(),
        data: (status) {
          if (status.connected && status.models.isNotEmpty) {
            final selectedModel = ref.watch(selectedOllamaModelProvider) ?? status.models.first;
            return Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ollama: Connected',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Active Model:',
                  style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                ),
                const SizedBox(width: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status.models.contains(selectedModel) ? selectedModel : status.models.first,
                    dropdownColor: AppColors.darkCard,
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                    items: status.models
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(selectedOllamaModelProvider.notifier).state = val;
                      }
                    },
                  ),
                ),
                const Spacer(),
                const Text(
                  '100% Local Execution',
                  style: TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                ),
              ],
            );
          }
          return _buildOfflineNotice();
        },
      ),
    );
  }

  Widget _buildOfflineNotice() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFF59E0B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Ollama: Offline',
          style: TextStyle(
            color: Color(0xFFF59E0B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Using Built-in Study Planner Engine (Run `ollama serve` to connect local LLM)',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11.5),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 15, color: AppColors.textDarkSecondary),
          tooltip: 'Retry Ollama Connection',
          onPressed: () => ref.invalidate(ollamaStatusProvider),
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildGeneratorCard() {
    final roadmapsAsync = ref.watch(roadmapsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: AppColors.primaryLight),
                  SizedBox(width: 6),
                  Text(
                    'Plan Parameters',
                    style: TextStyle(
                      color: AppColors.textDarkPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subject input
              const Text(
                'Subject or Learning Goal *',
                style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              TextFormField(
                key: const Key('ai_planner_subject_input'),
                controller: _subjectCtrl,
                style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 12.5),
                decoration: const InputDecoration(
                  hintText: 'e.g. Distributed Consensus in Go',
                  hintStyle: TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Subject is required' : null,
              ),
              const SizedBox(height: 8),

              // Suggestions
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: _quickSuggestions.map((s) {
                  return InkWell(
                    onTap: () => setState(() => _subjectCtrl.text = s),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppColors.darkBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 10),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Or based on existing roadmap
              roadmapsAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (roadmaps) {
                  if (roadmaps.isEmpty) return const SizedBox();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Or Link to Roadmap (Optional)',
                        style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedRoadmapId,
                        dropdownColor: AppColors.darkCard,
                        style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 12),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        hint: const Text('None (New Plan)', style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12)),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('None (Standalone)')),
                          ...roadmaps.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.title))),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedRoadmapId = val;
                            if (val != null) {
                              final rm = roadmaps.firstWhere((r) => r.id == val);
                              if (_subjectCtrl.text.isEmpty) _subjectCtrl.text = rm.title;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),

              // Proficiency level
              const Text(
                'Proficiency Level',
                style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                children: [
                  _buildChoiceChip('Beginner', 'beginner', const Color(0xFF10B981), _proficiency, (v) => setState(() => _proficiency = v)),
                  _buildChoiceChip('Intermediate', 'intermediate', const Color(0xFFF59E0B), _proficiency, (v) => setState(() => _proficiency = v)),
                  _buildChoiceChip('Advanced', 'advanced', const Color(0xFFEF4444), _proficiency, (v) => setState(() => _proficiency = v)),
                ],
              ),
              const SizedBox(height: 12),

              // Duration & Commitment
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Duration',
                          style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          children: [2, 4, 8, 12].map((w) {
                            final isSel = _targetWeeks == w;
                            return ChoiceChip(
                              label: Text('${w}W'),
                              selected: isSel,
                              selectedColor: AppColors.primary.withValues(alpha: 0.25),
                              backgroundColor: AppColors.darkBg,
                              side: BorderSide(color: isSel ? AppColors.primary : AppColors.darkBorder),
                              labelStyle: TextStyle(color: isSel ? AppColors.primaryLight : AppColors.textDarkSecondary, fontSize: 11),
                              onSelected: (_) => setState(() => _targetWeeks = w),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hours / Week',
                          style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          children: [5, 10, 15, 20].map((h) {
                            final isSel = _hoursPerWeek == h;
                            return ChoiceChip(
                              label: Text('${h}h'),
                              selected: isSel,
                              selectedColor: AppColors.accent.withValues(alpha: 0.25),
                              backgroundColor: AppColors.darkBg,
                              side: BorderSide(color: isSel ? AppColors.accent : AppColors.darkBorder),
                              labelStyle: TextStyle(color: isSel ? AppColors.accent : AppColors.textDarkSecondary, fontSize: 11),
                              onSelected: (_) => setState(() => _hoursPerWeek = h),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Focus Area
              const Text(
                'Focus Area',
                style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  'Practical Projects & Architecture',
                  'Core Concepts & Theory',
                  'Interview & Problem Solving',
                ].map((f) {
                  final isSel = _focusArea == f;
                  return ChoiceChip(
                    label: Text(f),
                    selected: isSel,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundColor: AppColors.darkBg,
                    side: BorderSide(color: isSel ? AppColors.primary : AppColors.darkBorder),
                    labelStyle: TextStyle(color: isSel ? AppColors.primaryLight : AppColors.textDarkSecondary, fontSize: 10.5),
                    onSelected: (_) => setState(() => _focusArea = f),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  key: const Key('ai_planner_generate_btn'),
                  icon: _isGenerating
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isGenerating ? 'Generating Syllabus...' : 'Generate Study Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isGenerating ? null : _handleGenerate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedPlansCard(
    AsyncValue<List<StudyPlanModel>> plansAsync,
    StudyPlanModel? selectedPlan,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saved Study Plans',
                style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              plansAsync.maybeWhen(
                data: (plans) => Text('${plans.length} plans', style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11)),
                orElse: () => const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: plansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error, fontSize: 11))),
              data: (plans) {
                if (plans.isEmpty) {
                  return const Center(
                    child: Text('No saved plans yet.', style: TextStyle(color: AppColors.textDarkMuted, fontSize: 12)),
                  );
                }
                return ListView.separated(
                  itemCount: plans.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (ctx, idx) {
                    final p = plans[idx];
                    final isSel = selectedPlan?.id == p.id;
                    return InkWell(
                      key: Key('ai_plan_item_${p.id}'),
                      onTap: () {
                        ref.read(selectedPlanIdProvider.notifier).state = p.id;
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.darkBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.darkBorder,
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSel ? AppColors.textDarkPrimary : AppColors.textDarkSecondary,
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${p.targetWeeks}W • ${p.hoursPerWeek}h/w • ${p.modelUsed}',
                                    style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                            if (p.isImported) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 11, color: Color(0xFF10B981)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanViewer(StudyPlanModel? plan) {
    if (plan == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology_outlined, size: 48, color: AppColors.primaryLight),
              SizedBox(height: 12),
              Text(
                'No Study Plan Selected',
                style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'Fill in the parameters on the left to generate an offline study plan.',
                style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          color: AppColors.textDarkPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: plan.proficiencyColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              plan.proficiency.toUpperCase(),
                              style: TextStyle(color: plan.proficiencyColor, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '${plan.totalHours} Total Hours • Model: ${plan.modelUsed}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                if (plan.isImported) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                    label: const Text('View in Roadmap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    ),
                    onPressed: () => context.go('/roadmap'),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    key: const Key('ai_plan_import_roadmap_btn'),
                    icon: _isImporting
                        ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add_to_photos_rounded, size: 15),
                    label: Text(_isImporting ? 'Importing...' : 'Convert to Roadmap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    ),
                    onPressed: _isImporting ? null : () => _handleImportRoadmap(plan.id),
                  ),
                ],
                const SizedBox(width: 8),

                // Copy Markdown button
                IconButton(
                  key: const Key('ai_plan_copy_btn'),
                  icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textDarkSecondary),
                  tooltip: 'Copy Markdown',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: plan.planMarkdown));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Study plan markdown copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                // Delete button
                IconButton(
                  key: const Key('ai_plan_delete_btn'),
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                  tooltip: 'Delete Plan',
                  onPressed: () => _confirmDeletePlan(plan.id),
                ),
              ],
            ),
          ),

          // Markdown Content Body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Markdown(
                key: const Key('ai_plan_markdown_viewer'),
                data: plan.planMarkdown,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13.5, height: 1.6),
                  h1: const TextStyle(color: AppColors.primaryLight, fontSize: 20, fontWeight: FontWeight.bold, height: 1.6),
                  h2: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.bold, height: 1.5),
                  h3: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.4),
                  blockquote: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12.5),
                  blockquoteDecoration: BoxDecoration(
                    color: AppColors.darkBg,
                    border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  code: const TextStyle(
                    backgroundColor: AppColors.darkBg,
                    color: AppColors.warning,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.darkBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  listBullet: const TextStyle(color: AppColors.primaryLight),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
    String label,
    String value,
    Color color,
    String current,
    ValueChanged<String> onSelected,
  ) {
    final isSel = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      selectedColor: color.withValues(alpha: 0.25),
      backgroundColor: AppColors.darkBg,
      side: BorderSide(color: isSel ? color : AppColors.darkBorder),
      labelStyle: TextStyle(
        color: isSel ? color : AppColors.textDarkSecondary,
        fontSize: 11,
        fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
      ),
      onSelected: (_) => onSelected(value),
    );
  }

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);
    try {
      final selectedModel = ref.read(selectedOllamaModelProvider);
      await ref.read(studyPlansListProvider.notifier).generatePlan(
            subject: _subjectCtrl.text,
            proficiency: _proficiency,
            hoursPerWeek: _hoursPerWeek,
            targetWeeks: _targetWeeks,
            focusArea: _focusArea,
            customInstructions: _constraintsCtrl.text,
            model: selectedModel,
            roadmapId: _selectedRoadmapId,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('Study plan generated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to generate study plan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _handleImportRoadmap(int planId) async {
    setState(() => _isImporting = true);
    try {
      await ref.read(studyPlansListProvider.notifier).importRoadmap(planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: const Text('Roadmap and practice projects created!'),
            action: SnackBarAction(
              label: 'View Roadmap',
              textColor: Colors.white,
              onPressed: () => context.go('/roadmap'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to import roadmap: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _confirmDeletePlan(int planId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Study Plan', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: const Text(
          'Are you sure you want to delete this generated study plan?',
          style: TextStyle(color: AppColors.textDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(studyPlansListProvider.notifier).deletePlan(planId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
