import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/recall_models.dart';

class QuizPlayerDialog extends StatefulWidget {
  final QuizModel quiz;
  const QuizPlayerDialog({super.key, required this.quiz});

  static void show(BuildContext context, QuizModel quiz) {
    showDialog(
      context: context,
      builder: (ctx) => QuizPlayerDialog(quiz: quiz),
    );
  }

  @override
  State<QuizPlayerDialog> createState() => _QuizPlayerDialogState();
}

class _QuizPlayerDialogState extends State<QuizPlayerDialog> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  int _score = 0;
  bool _isQuizFinished = false;

  @override
  Widget build(BuildContext context) {
    final questions = widget.quiz.questions;

    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: questions.isEmpty
              ? _buildEmptyQuiz()
              : _isQuizFinished
                  ? _buildScoreboard(questions.length)
                  : _buildQuestionView(questions),
        ),
      ),
    );
  }

  Widget _buildEmptyQuiz() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.quiz_outlined, size: 48, color: AppColors.textDarkMuted),
        const SizedBox(height: 12),
        const Text(
          'This quiz has no questions yet.',
          style: TextStyle(color: AppColors.textDarkPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildQuestionView(List<QuizQuestionModel> questions) {
    final q = questions[_currentIndex];
    final progress = (_currentIndex + 1) / questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.quiz.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDarkPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Question ${_currentIndex + 1} of ${questions.length} • Score: $_score',
                    style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 20, color: AppColors.textDarkSecondary),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.darkBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
          ),
        ),
        const SizedBox(height: 16),

        // Question text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Text(
            q.question,
            style: const TextStyle(
              color: AppColors.textDarkPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Options list
        Expanded(
          child: ListView.separated(
            itemCount: q.options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              return _buildOptionTile(q, idx);
            },
          ),
        ),

        // Explanation (if answered)
        if (_isAnswered && q.explanation != null && q.explanation!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q.explanation!,
                    style: const TextStyle(color: AppColors.textDarkPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Footer button
        if (_isAnswered)
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton.icon(
              key: const Key('quiz_next_question_btn'),
              icon: Icon(
                _currentIndex + 1 < questions.length ? Icons.arrow_forward_rounded : Icons.check_circle_rounded,
                size: 16,
              ),
              label: Text(_currentIndex + 1 < questions.length ? 'Next Question' : 'View Results'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (_currentIndex + 1 < questions.length) {
                  setState(() {
                    _currentIndex += 1;
                    _selectedOptionIndex = null;
                    _isAnswered = false;
                  });
                } else {
                  setState(() {
                    _isQuizFinished = true;
                  });
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _buildOptionTile(QuizQuestionModel q, int index) {
    final optionText = q.options[index];
    final isSelected = _selectedOptionIndex == index;
    final isCorrect = q.correctIndex == index;

    Color borderColor = AppColors.darkBorder;
    Color bgColor = AppColors.darkCard;
    Color textColor = AppColors.textDarkPrimary;
    Widget? trailingIcon;

    if (_isAnswered) {
      if (isCorrect) {
        borderColor = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
        textColor = const Color(0xFF10B981);
        trailingIcon = const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18);
      } else if (isSelected && !isCorrect) {
        borderColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        textColor = const Color(0xFFEF4444);
        trailingIcon = const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 18);
      }
    }

    final letter = String.fromCharCode(65 + index); // A, B, C, D

    return InkWell(
      key: Key('quiz_option_btn_$index'),
      onTap: _isAnswered
          ? null
          : () {
              setState(() {
                _selectedOptionIndex = index;
                _isAnswered = true;
                if (index == q.correctIndex) {
                  _score += 1;
                }
              });
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: isSelected || (_isAnswered && isCorrect) ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildScoreboard(int totalQuestions) {
    final percentage = (totalQuestions > 0 ? (_score / totalQuestions * 100) : 0.0).round();
    final isPassing = percentage >= 70;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isPassing ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPassing ? Icons.verified_rounded : Icons.psychology_rounded,
            size: 48,
            color: isPassing ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isPassing ? 'Outstanding Mastery!' : 'Keep Practicing!',
          style: const TextStyle(
            color: AppColors.textDarkPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'You answered $_score out of $totalQuestions questions correctly ($percentage%)',
          style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                  _selectedOptionIndex = null;
                  _isAnswered = false;
                  _score = 0;
                  _isQuizFinished = false;
                });
              },
              child: const Text('Retake Quiz'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ],
    );
  }
}
