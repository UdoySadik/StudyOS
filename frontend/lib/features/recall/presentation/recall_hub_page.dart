import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/recall_provider.dart';
import '../domain/recall_models.dart';
import 'flashcard_study_dialog.dart';
import 'quiz_player_dialog.dart';

class RecallHubPage extends ConsumerStatefulWidget {
  const RecallHubPage({super.key});

  @override
  ConsumerState<RecallHubPage> createState() => _RecallHubPageState();
}

class _RecallHubPageState extends ConsumerState<RecallHubPage> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final decksAsync = ref.watch(decksListProvider);
    final quizzesAsync = ref.watch(quizzesListProvider);

    final decks = decksAsync.valueOrNull ?? [];
    final quizzes = quizzesAsync.valueOrNull ?? [];

    final totalCards = decks.fold<int>(0, (sum, d) => sum + d.totalCards);
    final masteredCards = decks.fold<int>(0, (sum, d) => sum + d.masteredCards);
    final masteryRate = totalCards > 0 ? (masteredCards / totalCards) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildMetricsRow(
                totalDecks: decks.length,
                totalCards: totalCards,
                masteredCards: masteredCards,
                masteryRate: masteryRate,
                totalQuizzes: quizzes.length,
              ),
              const SizedBox(height: 20),

              // TabBar
              Container(
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
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.style_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text('Flashcard Decks (${decks.length})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.quiz_rounded, size: 16),
                          const SizedBox(width: 8),
                          Text('Interactive Quizzes (${quizzes.length})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // TabBarView
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildDecksList(decksAsync),
                    _buildQuizzesList(quizzesAsync),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Active Recall Hub',
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
                'AI and heuristic flashcard decks & quizzes generated directly from your topic study notes',
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
          key: const Key('generate_recall_modal_btn'),
          icon: const Icon(Icons.auto_awesome_rounded, size: 16),
          label: const Text('Generate from Notes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _showGenerateModal(context),
        ),
      ],
    );
  }

  Widget _buildMetricsRow({
    required int totalDecks,
    required int totalCards,
    required int masteredCards,
    required double masteryRate,
    required int totalQuizzes,
  }) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Flashcard Decks',
            value: '$totalDecks',
            icon: Icons.style_rounded,
            color: const Color(0xFF6366F1),
            subtitle: '$totalCards total cards',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            title: 'Mastery Rate',
            value: '${(masteryRate * 100).toStringAsFixed(0)}%',
            icon: Icons.verified_rounded,
            color: const Color(0xFF10B981),
            subtitle: '$masteredCards of $totalCards mastered',
            progress: masteryRate,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MetricCard(
            title: 'Interactive Quizzes',
            value: '$totalQuizzes',
            icon: Icons.quiz_rounded,
            color: const Color(0xFF06B6D4),
            subtitle: 'Multiple-choice testing',
          ),
        ),
      ],
    );
  }

  Widget _buildDecksList(AsyncValue<List<DeckModel>> decksAsync) {
    return decksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      data: (decks) {
        if (decks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.style_outlined, size: 48, color: AppColors.textDarkMuted),
                const SizedBox(height: 14),
                const Text(
                  'No flashcard decks yet',
                  style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Click "Generate from Notes" above or study notes to create flashcard decks.',
                  style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Generate First Deck'),
                  onPressed: () => _showGenerateModal(context),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: decks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) => _buildDeckCard(decks[idx]),
        );
      },
    );
  }

  Widget _buildDeckCard(DeckModel deck) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.style_rounded, color: AppColors.primaryLight, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        deck.title,
                        style: const TextStyle(
                          color: AppColors.textDarkPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (deck.topicTitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          deck.topicTitle!,
                          style: const TextStyle(color: AppColors.accent, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  deck.description ?? 'Flashcard deck for active recall',
                  style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: deck.masteryPercent,
                          minHeight: 4,
                          backgroundColor: AppColors.darkBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${deck.masteredCards} / ${deck.totalCards} Mastered (${(deck.masteryPercent * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            key: Key('study_deck_btn_${deck.id}'),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Study Deck'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
            onPressed: () => FlashcardStudyDialog.show(context, deck),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            tooltip: 'Delete Deck',
            onPressed: () => _confirmDeleteDeck(deck.id),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesList(AsyncValue<List<QuizModel>> quizzesAsync) {
    return quizzesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.error))),
      data: (quizzes) {
        if (quizzes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.quiz_outlined, size: 48, color: AppColors.textDarkMuted),
                const SizedBox(height: 14),
                const Text(
                  'No quizzes created yet',
                  style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Generate quizzes from your topic study notes for active recall self-testing.',
                  style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Generate First Quiz'),
                  onPressed: () => _showGenerateModal(context),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: quizzes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) => _buildQuizCard(quizzes[idx]),
        );
      },
    );
  }

  Widget _buildQuizCard(QuizModel quiz) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.quiz_rounded, color: Color(0xFF06B6D4), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quiz.title,
                        style: const TextStyle(
                          color: AppColors.textDarkPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (quiz.topicTitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quiz.topicTitle!,
                          style: const TextStyle(color: AppColors.primaryLight, fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  quiz.description ?? 'Self-test multiple choice quiz',
                  style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  '${quiz.questionsCount} Multiple Choice Questions',
                  style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            key: Key('start_quiz_btn_${quiz.id}'),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF06B6D4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
            onPressed: () => QuizPlayerDialog.show(context, quiz),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
            tooltip: 'Delete Quiz',
            onPressed: () => _confirmDeleteQuiz(quiz.id),
          ),
        ],
      ),
    );
  }

  void _showGenerateModal(BuildContext context) {
    GenerateRecallDialog.show(context);
  }

  void _confirmDeleteDeck(int deckId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Deck', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: const Text('Are you sure you want to delete this flashcard deck?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(decksListProvider.notifier).deleteDeck(deckId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteQuiz(int quizId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text('Delete Quiz', style: TextStyle(color: AppColors.textDarkPrimary)),
        content: const Text('Are you sure you want to delete this quiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textDarkSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref.read(quizzesListProvider.notifier).deleteQuiz(quizId);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Metric Card ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final double? progress;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
              Text(title, style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.darkBorder,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(subtitle, style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Generate Modal Dialog ───────────────────────────────────────────────────

class GenerateRecallDialog extends ConsumerStatefulWidget {
  final int? preselectedTopicId;
  final String? preselectedTopicTitle;

  const GenerateRecallDialog({
    super.key,
    this.preselectedTopicId,
    this.preselectedTopicTitle,
  });

  static void show(
    BuildContext context, {
    int? preselectedTopicId,
    String? preselectedTopicTitle,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => GenerateRecallDialog(
        preselectedTopicId: preselectedTopicId,
        preselectedTopicTitle: preselectedTopicTitle,
      ),
    );
  }

  @override
  ConsumerState<GenerateRecallDialog> createState() => _GenerateRecallDialogState();
}

class _GenerateRecallDialogState extends ConsumerState<GenerateRecallDialog> {
  final _manualTextCtrl = TextEditingController();
  int _count = 5;
  bool _genFlashcards = true;
  bool _genQuiz = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _manualTextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Generate Flashcards & Quiz',
                      style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: AppColors.textDarkSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 18, color: AppColors.darkBorder),
              const SizedBox(height: 8),

              if (widget.preselectedTopicTitle != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, size: 15, color: AppColors.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        'Topic: ${widget.preselectedTopicTitle}',
                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ] else ...[
                const Text(
                  'Paste Study Notes (or leave empty to generate from topic)',
                  style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('generate_recall_notes_input'),
                  controller: _manualTextCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 12.5),
                  decoration: const InputDecoration(
                    hintText: 'Paste Markdown notes, concepts, definitions or code snippets...',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Card / Question count
              const Text(
                'Number of Items to Generate',
                style: TextStyle(color: AppColors.textDarkSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [3, 5, 8, 10].map((c) {
                  final isSel = _count == c;
                  return ChoiceChip(
                    label: Text('$c items'),
                    selected: isSel,
                    selectedColor: AppColors.primary.withValues(alpha: 0.25),
                    backgroundColor: AppColors.darkCard,
                    side: BorderSide(color: isSel ? AppColors.primary : AppColors.darkBorder),
                    labelStyle: TextStyle(color: isSel ? AppColors.primaryLight : AppColors.textDarkSecondary, fontSize: 11.5),
                    onSelected: (_) => setState(() => _count = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Checkboxes
              CheckboxListTile(
                value: _genFlashcards,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.primary,
                title: const Text('Generate Flashcard Deck', style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 13)),
                onChanged: (val) => setState(() => _genFlashcards = val ?? true),
              ),
              CheckboxListTile(
                value: _genQuiz,
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: const Color(0xFF06B6D4),
                title: const Text('Generate Multiple-Choice Quiz', style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 13)),
                onChanged: (val) => setState(() => _genQuiz = val ?? true),
              ),
              const SizedBox(height: 18),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  key: const Key('generate_recall_submit_btn'),
                  icon: _isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.auto_awesome, size: 16),
                  label: Text(_isSubmitting ? 'Generating Active Recall...' : 'Generate Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSubmitting ? null : _submitGenerate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitGenerate() async {
    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(decksListProvider.notifier);
      final result = await notifier.generateFromNote(
        topicId: widget.preselectedTopicId,
        noteContent: _manualTextCtrl.text.isNotEmpty ? _manualTextCtrl.text : null,
        count: _count,
        generateFlashcards: _genFlashcards,
        generateQuiz: _genQuiz,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text(
              'Generated ${result.generatedCardsCount} cards & ${result.generatedQuestionsCount} quiz questions via ${result.modelUsed}!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to generate recall items: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
