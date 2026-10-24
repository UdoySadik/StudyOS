import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/recall/application/recall_provider.dart';
import 'package:studyos/features/recall/domain/recall_models.dart';
import 'package:studyos/features/recall/presentation/flashcard_study_dialog.dart';
import 'package:studyos/features/recall/presentation/quiz_player_dialog.dart';
import 'package:studyos/features/recall/presentation/recall_hub_page.dart';

class _MockDecksNotifier extends DecksListNotifier {
  final List<DeckModel> initialDecks;
  _MockDecksNotifier(this.initialDecks);

  @override
  Future<List<DeckModel>> build() async {
    return initialDecks;
  }

  @override
  Future<void> toggleMastery(int cardId, bool isMastered) async {}
}

class _MockQuizzesNotifier extends QuizzesListNotifier {
  final List<QuizModel> initialQuizzes;
  _MockQuizzesNotifier(this.initialQuizzes);

  @override
  Future<List<QuizModel>> build() async {
    return initialQuizzes;
  }
}

void main() {
  group('Recall Domain Models Tests', () {
    test('FlashcardModel and DeckModel serialize/deserialize correctly', () {
      final cardJson = {
        'id': 1,
        'deck_id': 10,
        'front': 'What is Rust ownership?',
        'back': 'Each value has an owner; only one owner at a time.',
        'is_mastered': true,
        'review_count': 3,
        'created_at': '2026-10-24T12:00:00.000Z',
      };

      final card = FlashcardModel.fromJson(cardJson);
      expect(card.id, 1);
      expect(card.deckId, 10);
      expect(card.front, 'What is Rust ownership?');
      expect(card.back, 'Each value has an owner; only one owner at a time.');
      expect(card.isMastered, true);
      expect(card.reviewCount, 3);

      final deckJson = {
        'id': 10,
        'title': 'Rust Memory Model',
        'description': 'Ownership and Lifetimes',
        'topic_id': 5,
        'topic_title': 'Rust Basics',
        'cards': [cardJson],
        'created_at': '2026-10-24T12:00:00.000Z',
      };

      final deck = DeckModel.fromJson(deckJson);
      expect(deck.id, 10);
      expect(deck.title, 'Rust Memory Model');
      expect(deck.totalCards, 1);
      expect(deck.masteredCards, 1);
      expect(deck.masteryPercent, 1.0);
      expect(deck.cards.first.front, card.front);

      final copy = card.copyWith(isMastered: false, reviewCount: 4);
      expect(copy.isMastered, false);
      expect(copy.reviewCount, 4);
    });

    test('QuizQuestionModel and QuizModel serialize/deserialize correctly', () {
      final qJson = {
        'id': 101,
        'quiz_id': 20,
        'question': 'Which keyword declares an immutable variable by default in Rust?',
        'options': ['let', 'var', 'const', 'val'],
        'correct_index': 0,
        'explanation': 'In Rust, variables defined with let are immutable by default.',
      };

      final question = QuizQuestionModel.fromJson(qJson);
      expect(question.id, 101);
      expect(question.quizId, 20);
      expect(question.options.length, 4);
      expect(question.correctOption, 'let');
      expect(question.correctIndex, 0);

      final quizJson = {
        'id': 20,
        'title': 'Rust Syntax Quiz',
        'description': 'Check your understanding of variable bindings',
        'topic_id': 5,
        'topic_title': 'Rust Basics',
        'questions': [qJson],
        'created_at': '2026-10-24T12:00:00.000Z',
      };

      final quiz = QuizModel.fromJson(quizJson);
      expect(quiz.id, 20);
      expect(quiz.title, 'Rust Syntax Quiz');
      expect(quiz.questionsCount, 1);
      expect(quiz.questions.first.question, question.question);
    });

    test('GenerateRecallResult deserializes correctly', () {
      final resJson = {
        'model_used': 'ollama:llama3.2',
        'generated_cards_count': 5,
        'generated_questions_count': 4,
        'deck': null,
        'quiz': null,
      };

      final result = GenerateRecallResult.fromJson(resJson);
      expect(result.modelUsed, 'ollama:llama3.2');
      expect(result.generatedCardsCount, 5);
      expect(result.generatedQuestionsCount, 4);
      expect(result.deck, isNull);
      expect(result.quiz, isNull);
    });
  });

  group('FlashcardStudyDialog Widget Tests', () {
    testWidgets('Flashcard study dialog shows front, flips to back on tap, and tracks mastery', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const deck = DeckModel(
        id: 1,
        title: 'Operating Systems',
        description: 'Processes and Threads',
        totalCards: 2,
        cards: [
          FlashcardModel(
            id: 1,
            deckId: 1,
            front: 'What is a process control block (PCB)?',
            back: 'A data structure used by OS to store all information about a process.',
            isMastered: false,
            reviewCount: 1,
          ),
          FlashcardModel(
            id: 2,
            deckId: 1,
            front: 'What is a context switch?',
            back: 'Switching CPU core from one process to another, saving PCB state.',
            isMastered: true,
            reviewCount: 2,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            decksListProvider.overrideWith(() => _MockDecksNotifier([deck])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => FlashcardStudyDialog.show(context, deck),
                  child: const Text('Open Flashcards'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Flashcards'));
      await tester.pumpAndSettle();

      // Verify header and initial front text
      expect(find.text('Operating Systems'), findsOneWidget);
      expect(find.textContaining('Card 1 of 2'), findsOneWidget);
      expect(find.text('What is a process control block (PCB)?'), findsOneWidget);

      // Tap card to flip
      await tester.tap(find.byKey(const Key('flashcard_flip_target')));
      await tester.pumpAndSettle();

      // Verify back text is revealed
      expect(find.text('A data structure used by OS to store all information about a process.'), findsOneWidget);

      // Next card via mastered button
      await tester.tap(find.byKey(const Key('flashcard_mastered_btn')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Card 2 of 2'), findsOneWidget);
      expect(find.text('What is a context switch?'), findsOneWidget);
    });
  });

  group('QuizPlayerDialog Widget Tests', () {
    testWidgets('Quiz player dialog renders options, provides immediate feedback and summary', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const quiz = QuizModel(
        id: 1,
        title: 'Computer Networks Quiz',
        description: 'Transport layer concepts',
        questionsCount: 1,
        questions: [
          QuizQuestionModel(
            id: 10,
            quizId: 1,
            question: 'Which protocol is connection-oriented and provides reliable byte streams?',
            options: ['UDP', 'TCP', 'IP', 'ICMP'],
            correctIndex: 1,
            explanation: 'TCP guarantees delivery and ordered stream transmission.',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => QuizPlayerDialog.show(context, quiz),
                  child: const Text('Start Quiz'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Start Quiz'));
      await tester.pumpAndSettle();

      // Verify question and options
      expect(find.text('Computer Networks Quiz'), findsOneWidget);
      expect(find.textContaining('Question 1 of 1'), findsOneWidget);
      expect(find.text('Which protocol is connection-oriented and provides reliable byte streams?'), findsOneWidget);
      expect(find.text('TCP'), findsOneWidget);
      expect(find.text('UDP'), findsOneWidget);

      // Select TCP (index 1) - clicking option automatically submits
      await tester.tap(find.byKey(const Key('quiz_option_btn_1')));
      await tester.pumpAndSettle();

      // Explanation banner and feedback
      expect(find.textContaining('TCP guarantees delivery'), findsOneWidget);

      // View results button
      expect(find.byKey(const Key('quiz_next_question_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('quiz_next_question_btn')));
      await tester.pumpAndSettle();

      // Score summary screen
      expect(find.text('Outstanding Mastery!'), findsOneWidget);
      expect(find.textContaining('1 out of 1 questions correctly (100%)'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });
  });

  group('RecallHubPage Widget Tests', () {
    testWidgets('RecallHubPage renders metrics, decks list, and opens generate modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const testDeck = DeckModel(
        id: 1,
        title: 'Algorithms Deck',
        description: 'Sorting & Graphs',
        topicTitle: 'Algorithms',
        totalCards: 1,
        masteredCards: 1,
        cards: [
          FlashcardModel(
            id: 1,
            deckId: 1,
            front: 'What is QuickSort average time complexity?',
            back: 'O(n log n)',
            isMastered: true,
          ),
        ],
      );

      const testQuiz = QuizModel(
        id: 1,
        title: 'Algorithms Quiz',
        description: 'Test sorting knowledge',
        topicTitle: 'Algorithms',
        questionsCount: 1,
        questions: [
          QuizQuestionModel(
            id: 1,
            quizId: 1,
            question: 'Is MergeSort stable?',
            options: ['Yes', 'No'],
            correctIndex: 0,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            decksListProvider.overrideWith(() => _MockDecksNotifier([testDeck])),
            quizzesListProvider.overrideWith(() => _MockQuizzesNotifier([testQuiz])),
          ],
          child: const MaterialApp(
            home: RecallHubPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header and Metrics
      expect(find.text('Active Recall Hub'), findsOneWidget);
      expect(find.text('Flashcard Decks'), findsOneWidget);
      expect(find.text('Interactive Quizzes'), findsOneWidget);
      expect(find.textContaining('1 / 1 Mastered (100%)'), findsOneWidget);

      // Deck card
      expect(find.text('Algorithms Deck'), findsOneWidget);
      expect(find.byKey(const Key('study_deck_btn_1')), findsOneWidget);

      // Tap generate modal button
      await tester.tap(find.byKey(const Key('generate_recall_modal_btn')));
      await tester.pumpAndSettle();

      // Verify modal opened
      expect(find.text('Generate Flashcards & Quiz'), findsOneWidget);
      expect(find.byKey(const Key('generate_recall_submit_btn')), findsOneWidget);
    });
  });
}
