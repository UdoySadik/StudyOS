import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/note_ai_provider.dart';
import '../domain/note_ai_models.dart';

class NoteAIDialog extends ConsumerStatefulWidget {
  final int? topicId;
  final String? topicTitle;
  final String? initialNoteContent;
  final ValueChanged<String>? onInsertAtTop;
  final ValueChanged<String>? onAppendToEnd;

  const NoteAIDialog({
    super.key,
    this.topicId,
    this.topicTitle,
    this.initialNoteContent,
    this.onInsertAtTop,
    this.onAppendToEnd,
  });

  static void show(
    BuildContext context, {
    int? topicId,
    String? topicTitle,
    String? noteContent,
    ValueChanged<String>? onInsertAtTop,
    ValueChanged<String>? onAppendToEnd,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => NoteAIDialog(
        topicId: topicId,
        topicTitle: topicTitle,
        initialNoteContent: noteContent,
        onInsertAtTop: onInsertAtTop,
        onAppendToEnd: onAppendToEnd,
      ),
    );
  }

  @override
  ConsumerState<NoteAIDialog> createState() => _NoteAIDialogState();
}

class _NoteAIDialogState extends ConsumerState<NoteAIDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Summarizer state
  String _selectedStyle = 'key_takeaways';
  int _maxBullets = 5;
  bool _isSummarizing = false;
  NoteSummarizeResult? _summaryResult;

  // Explainer state
  final _conceptCtrl = TextEditingController();
  String _selectedDepth = 'intermediate';
  bool _isExplaining = false;
  ConceptExplainResult? _explainResult;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.topicTitle != null && widget.topicTitle!.isNotEmpty) {
      _conceptCtrl.text = widget.topicTitle!;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _conceptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 14),
              _buildTabBar(),
              const SizedBox(height: 14),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildSummarizerTab(),
                    _buildExplainerTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Study Assistant',
                style: TextStyle(
                  color: AppColors.textDarkPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.topicTitle != null
                    ? 'Topic: ${widget.topicTitle}'
                    : 'Smart Note Summarization & Concept Explainer',
                style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20, color: AppColors.textDarkSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primaryLight,
        unselectedLabelColor: AppColors.textDarkSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        tabs: const [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.summarize_rounded, size: 16),
                SizedBox(width: 8),
                Text('Smart Summarizer'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_rounded, size: 16),
                SizedBox(width: 8),
                Text('Concept Explainer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Smart Summarizer ─────────────────────────────────────────────────

  Widget _buildSummarizerTab() {
    final styles = [
      {'key': 'key_takeaways', 'label': 'Key Takeaways', 'icon': Icons.lightbulb_outline},
      {'key': 'executive', 'label': 'Executive Brief', 'icon': Icons.assignment_outlined},
      {'key': 'bullet_points', 'label': 'Bullet Points', 'icon': Icons.format_list_bulleted},
      {'key': 'cheat_sheet', 'label': 'Cheat Sheet', 'icon': Icons.table_chart_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Controls Row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...styles.map((s) {
              final isSel = _selectedStyle == s['key'];
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s['icon'] as IconData, size: 14, color: isSel ? AppColors.primaryLight : AppColors.textDarkSecondary),
                    const SizedBox(width: 6),
                    Text(s['label'] as String),
                  ],
                ),
                selected: isSel,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundColor: AppColors.darkCard,
                side: BorderSide(color: isSel ? AppColors.primary : AppColors.darkBorder),
                labelStyle: TextStyle(
                  color: isSel ? AppColors.primaryLight : AppColors.textDarkSecondary,
                  fontSize: 11.5,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                ),
                onSelected: (_) => setState(() => _selectedStyle = s['key'] as String),
              );
            }),
            const SizedBox(width: 4),
            // Max bullets
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Bullets: ', style: TextStyle(color: AppColors.textDarkMuted, fontSize: 11)),
                  DropdownButton<int>(
                    value: _maxBullets,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.darkCard,
                    isDense: true,
                    style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 11.5, fontWeight: FontWeight.w600),
                    items: [3, 5, 8, 10].map((c) => DropdownMenuItem(value: c, child: Text('$c'))).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _maxBullets = v);
                    },
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              key: const Key('note_ai_summarize_btn'),
              icon: _isSummarizing
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 14),
              label: Text(_isSummarizing ? 'Summarizing...' : 'Summarize Note'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isSummarizing ? null : _runSummarize,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Summary viewer area
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: _summaryResult == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.summarize_outlined, size: 40, color: AppColors.textDarkMuted),
                        const SizedBox(height: 10),
                        const Text(
                          'No summary generated yet',
                          style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Click "Summarize Note" to generate an executive brief or key takeaways.',
                          style: TextStyle(color: AppColors.textDarkSecondary.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Meta Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _summaryResult!.modelUsed,
                                style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '📝 ${_summaryResult!.wordCount} words',
                              style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11.5),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '⏱️ ${_summaryResult!.readingTimeMinutes} min read',
                              style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11.5),
                            ),
                            const Spacer(),
                            IconButton(
                              key: const Key('note_ai_copy_summary_btn'),
                              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textDarkSecondary),
                              tooltip: 'Copy to Clipboard',
                              onPressed: () => _copyText(_summaryResult!.summaryMarkdown),
                            ),
                          ],
                        ),
                      ),
                      // Markdown Viewer
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Markdown(
                            key: const Key('note_ai_summary_viewer'),
                            data: _summaryResult!.summaryMarkdown,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13, height: 1.5),
                              h3: const TextStyle(color: AppColors.primaryLight, fontSize: 15, fontWeight: FontWeight.w700),
                              h4: const TextStyle(color: AppColors.accent, fontSize: 13.5, fontWeight: FontWeight.w600),
                              code: const TextStyle(backgroundColor: AppColors.darkBg, color: AppColors.warning),
                            ),
                          ),
                        ),
                      ),
                      // Insertion actions
                      if (widget.onInsertAtTop != null || widget.onAppendToEnd != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.darkBorder)),
                          ),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              if (widget.onInsertAtTop != null)
                                OutlinedButton.icon(
                                  key: const Key('note_ai_insert_top_btn'),
                                  icon: const Icon(Icons.vertical_align_top_rounded, size: 15),
                                  label: const Text('Insert at Top of Note', style: TextStyle(fontSize: 12)),
                                  onPressed: () {
                                    widget.onInsertAtTop!(_summaryResult!.summaryMarkdown);
                                    Navigator.pop(context);
                                  },
                                ),
                              if (widget.onAppendToEnd != null)
                                ElevatedButton.icon(
                                  key: const Key('note_ai_append_summary_btn'),
                                  icon: const Icon(Icons.vertical_align_bottom_rounded, size: 15),
                                  label: const Text('Append to Note', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    widget.onAppendToEnd!(_summaryResult!.summaryMarkdown);
                                    Navigator.pop(context);
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _runSummarize() async {
    setState(() => _isSummarizing = true);
    try {
      final service = ref.read(noteAIProvider);
      final res = await service.summarizeNote(
        topicId: widget.topicId,
        noteContent: widget.initialNoteContent,
        summaryStyle: _selectedStyle,
        maxBullets: _maxBullets,
      );
      if (mounted) {
        setState(() {
          _summaryResult = res;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to summarize note: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  // ── Tab 2: Concept Explainer ────────────────────────────────────────────────

  Widget _buildExplainerTab() {
    final depths = [
      {'key': 'beginner', 'label': 'Beginner (ELI5)', 'icon': Icons.child_care_rounded},
      {'key': 'intermediate', 'label': 'Intermediate', 'icon': Icons.tune_rounded},
      {'key': 'expert', 'label': 'Deep Dive', 'icon': Icons.code_rounded},
      {'key': 'analogies', 'label': 'Analogy', 'icon': Icons.palette_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: TextField(
                  key: const Key('note_ai_concept_input'),
                  controller: _conceptCtrl,
                  style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Enter concept or term (e.g., Raft, Ownership, Paging)...',
                    hintStyle: TextStyle(color: AppColors.textDarkMuted, fontSize: 12),
                    prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textDarkMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              key: const Key('note_ai_explain_btn'),
              icon: _isExplaining
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lightbulb_rounded, size: 14),
              label: Text(_isExplaining ? 'Explaining...' : 'Explain Concept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isExplaining ? null : _runExplain,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Depth selector chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: depths.map((d) {
            final isSel = _selectedDepth == d['key'];
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(d['icon'] as IconData, size: 14, color: isSel ? const Color(0xFF06B6D4) : AppColors.textDarkSecondary),
                  const SizedBox(width: 6),
                  Text(d['label'] as String),
                ],
              ),
              selected: isSel,
              selectedColor: const Color(0xFF06B6D4).withValues(alpha: 0.2),
              backgroundColor: AppColors.darkCard,
              side: BorderSide(color: isSel ? const Color(0xFF06B6D4) : AppColors.darkBorder),
              labelStyle: TextStyle(
                color: isSel ? Colors.white : AppColors.textDarkSecondary,
                fontSize: 11.5,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
              ),
              onSelected: (_) => setState(() => _selectedDepth = d['key'] as String),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Result container
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: _explainResult == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 40, color: AppColors.textDarkMuted),
                        const SizedBox(height: 10),
                        const Text(
                          'No concept explanation generated',
                          style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter any concept above and select depth to generate a structured breakdown.',
                          style: TextStyle(color: AppColors.textDarkSecondary.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _explainResult!.modelUsed,
                                style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '🎯 Depth: ${_explainResult!.depth.toUpperCase()}',
                              style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            IconButton(
                              key: const Key('note_ai_copy_explain_btn'),
                              icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textDarkSecondary),
                              tooltip: 'Copy Explanation',
                              onPressed: () => _copyText(_explainResult!.explanationMarkdown),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Markdown(
                            key: const Key('note_ai_explain_viewer'),
                            data: _explainResult!.explanationMarkdown,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 13, height: 1.5),
                              h3: const TextStyle(color: Color(0xFF06B6D4), fontSize: 15, fontWeight: FontWeight.w700),
                              h4: const TextStyle(color: AppColors.accent, fontSize: 13.5, fontWeight: FontWeight.w600),
                              code: const TextStyle(backgroundColor: AppColors.darkBg, color: AppColors.warning),
                              codeblockDecoration: BoxDecoration(
                                color: AppColors.darkBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.darkBorder),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (widget.onAppendToEnd != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: AppColors.darkBorder)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                key: const Key('note_ai_append_explain_btn'),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Append Explanation to Note', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF06B6D4),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  widget.onAppendToEnd!(_explainResult!.explanationMarkdown);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _runExplain() async {
    final term = _conceptCtrl.text.trim();
    if (term.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a concept name to explain.')),
      );
      return;
    }

    setState(() => _isExplaining = true);
    try {
      final service = ref.read(noteAIProvider);
      final res = await service.explainConcept(
        concept: term,
        context: widget.initialNoteContent,
        depth: _selectedDepth,
      );
      if (mounted) {
        setState(() {
          _explainResult = res;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to explain concept: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExplaining = false);
    }
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF10B981),
        content: Text('Copied to clipboard!'),
      ),
    );
  }
}
