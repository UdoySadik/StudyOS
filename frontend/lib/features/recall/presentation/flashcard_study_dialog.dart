import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/recall_provider.dart';
import '../domain/recall_models.dart';

class FlashcardStudyDialog extends ConsumerStatefulWidget {
  final DeckModel deck;
  const FlashcardStudyDialog({super.key, required this.deck});

  static void show(BuildContext context, DeckModel deck) {
    showDialog(
      context: context,
      builder: (ctx) => FlashcardStudyDialog(deck: deck),
    );
  }

  @override
  ConsumerState<FlashcardStudyDialog> createState() => _FlashcardStudyDialogState();
}

class _FlashcardStudyDialogState extends ConsumerState<FlashcardStudyDialog> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  final Set<int> _sessionMasteredIds = {};
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    for (final c in widget.deck.cards) {
      if (c.isMastered) _sessionMasteredIds.add(c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.deck.cards;

    return Dialog(
      backgroundColor: AppColors.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.darkBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: cards.isEmpty
              ? _buildEmptyDeck()
              : _isFinished
                  ? _buildFinishedState(cards.length)
                  : _buildStudyView(cards),
        ),
      ),
    );
  }

  Widget _buildEmptyDeck() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.style_outlined, size: 48, color: AppColors.textDarkMuted),
        const SizedBox(height: 12),
        const Text(
          'This deck has no cards yet.',
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

  Widget _buildStudyView(List<FlashcardModel> cards) {
    final currentCard = cards[_currentIndex];
    final isCardMastered = _sessionMasteredIds.contains(currentCard.id);
    final progress = (_currentIndex + 1) / cards.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.deck.title,
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
                    'Card ${_currentIndex + 1} of ${cards.length} • ${_sessionMasteredIds.length} Mastered',
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
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),

        // Flip Card
        Expanded(
          child: InkWell(
            key: const Key('flashcard_flip_target'),
            onTap: () => setState(() => _isFlipped = !_isFlipped),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _isFlipped ? const Color(0xFF1F2233) : AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isFlipped ? AppColors.primary : AppColors.darkBorder,
                  width: _isFlipped ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isFlipped
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isFlipped ? 'ANSWER / KEY CONCEPT' : 'QUESTION / PROMPT',
                      style: TextStyle(
                        color: _isFlipped ? AppColors.primaryLight : AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          _isFlipped ? currentCard.back : currentCard.front,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textDarkPrimary,
                            fontSize: _isFlipped ? 15 : 18,
                            fontWeight: _isFlipped ? FontWeight.w500 : FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.textDarkMuted),
                      const SizedBox(width: 5),
                      Text(
                        _isFlipped ? 'Tap card to flip to question' : 'Tap card to reveal answer',
                        style: const TextStyle(color: AppColors.textDarkMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            // Review again
            OutlinedButton.icon(
              key: const Key('flashcard_review_again_btn'),
              icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFF59E0B)),
              label: const Text('Review Again', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _sessionMasteredIds.remove(currentCard.id);
                ref.read(decksListProvider.notifier).toggleMastery(currentCard.id, false);
                _advanceNext(cards.length);
              },
            ),

            // Flip Button
            TextButton.icon(
              icon: const Icon(Icons.flip_rounded, size: 16),
              label: Text(_isFlipped ? 'Show Front' : 'Flip Card'),
              onPressed: () => setState(() => _isFlipped = !_isFlipped),
            ),

            // Mastered
            ElevatedButton.icon(
              key: const Key('flashcard_mastered_btn'),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: Text(isCardMastered ? 'Mastered!' : 'I Know This'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                _sessionMasteredIds.add(currentCard.id);
                ref.read(decksListProvider.notifier).toggleMastery(currentCard.id, true);
                _advanceNext(cards.length);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _advanceNext(int total) {
    if (_currentIndex + 1 < total) {
      setState(() {
        _currentIndex += 1;
        _isFlipped = false;
      });
    } else {
      setState(() {
        _isFinished = true;
      });
    }
  }

  Widget _buildFinishedState(int totalCards) {
    final masteredCount = _sessionMasteredIds.length;
    final percent = (masteredCount / totalCards * 100).toStringAsFixed(0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.celebration_rounded, size: 44, color: Color(0xFF10B981)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Deck Review Complete!',
          style: TextStyle(
            color: AppColors.textDarkPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You mastered $masteredCount of $totalCards cards ($percent%)',
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
                  _isFlipped = false;
                  _isFinished = false;
                });
              },
              child: const Text('Study Again'),
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
