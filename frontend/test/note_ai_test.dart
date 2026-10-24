import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/notes/application/note_ai_provider.dart';
import 'package:studyos/features/notes/domain/note_ai_models.dart';
import 'package:studyos/features/notes/presentation/note_ai_dialog.dart';

class _MockNoteAIService extends NoteAIService {
  final NoteSummarizeResult mockSummary;
  final ConceptExplainResult mockExplanation;

  _MockNoteAIService({
    required this.mockSummary,
    required this.mockExplanation,
  });

  @override
  Future<NoteSummarizeResult> summarizeNote({
    int? topicId,
    String? noteContent,
    String summaryStyle = 'key_takeaways',
    int maxBullets = 5,
    String? model,
  }) async {
    return mockSummary;
  }

  @override
  Future<ConceptExplainResult> explainConcept({
    required String concept,
    String? context,
    String depth = 'intermediate',
    String? model,
  }) async {
    return mockExplanation;
  }
}

void main() {
  group('Note AI Domain Models Tests', () {
    test('NoteSummarizeResult serializes and deserializes correctly', () {
      final json = {
        'summary_markdown': '### 💡 Key Takeaways: Raft\n- Leader election avoids split votes.',
        'key_takeaways': ['Leader election avoids split votes.'],
        'model_used': 'builtin-offline',
        'word_count': 42,
        'reading_time_minutes': 0.2,
      };

      final result = NoteSummarizeResult.fromJson(json);
      expect(result.summaryMarkdown, contains('Key Takeaways'));
      expect(result.keyTakeaways.length, 1);
      expect(result.keyTakeaways.first, 'Leader election avoids split votes.');
      expect(result.modelUsed, 'builtin-offline');
      expect(result.wordCount, 42);
      expect(result.readingTimeMinutes, 0.2);

      final exported = result.toJson();
      expect(exported['word_count'], 42);
      expect(exported['model_used'], 'builtin-offline');
    });

    test('ConceptExplainResult serializes and deserializes correctly', () {
      final json = {
        'concept': 'Virtual Memory',
        'depth': 'beginner',
        'explanation_markdown': '### 🐣 Beginner Guide: Virtual Memory\n\nVirtual memory provides an illusion of vast RAM.',
        'key_points': ['Page tables map addresses', 'TLB speeds up lookup'],
        'analogy': 'Like an index in a library book.',
        'example_snippet': 'fn lookup_page(addr: u64) -> u64',
        'model_used': 'ollama:llama3.2',
      };

      final result = ConceptExplainResult.fromJson(json);
      expect(result.concept, 'Virtual Memory');
      expect(result.depth, 'beginner');
      expect(result.explanationMarkdown, contains('Beginner Guide'));
      expect(result.keyPoints.length, 2);
      expect(result.analogy, 'Like an index in a library book.');
      expect(result.exampleSnippet, contains('lookup_page'));
      expect(result.modelUsed, 'ollama:llama3.2');

      final exported = result.toJson();
      expect(exported['concept'], 'Virtual Memory');
      expect(exported['depth'], 'beginner');
    });
  });

  group('NoteAIDialog Presentation Widget Tests', () {
    const testSummary = NoteSummarizeResult(
      summaryMarkdown: '### 💡 Key Takeaways: Rust Lifetimes\n- Lifetimes ensure references never outlive their data.\n- The borrow checker prevents dangling pointers at compile time.',
      keyTakeaways: [
        'Lifetimes ensure references never outlive their data.',
        'The borrow checker prevents dangling pointers at compile time.',
      ],
      modelUsed: 'builtin-offline',
      wordCount: 28,
      readingTimeMinutes: 0.1,
    );

    const testExplanation = ConceptExplainResult(
      concept: 'Raft Consensus',
      depth: 'expert',
      explanationMarkdown: '### 🚀 Technical Deep Dive: Raft Consensus\n\nRaft decomposes consensus into leader election, log replication, and safety.',
      keyPoints: ['Leader election via randomized election timeouts', 'Log matching invariant guarantees linearizability'],
      analogy: 'Consensus is like parliamentary voting under strict quorum rules.',
      exampleSnippet: 'struct RaftNode { current_term: u64 }',
      modelUsed: 'builtin-offline',
    );

    testWidgets('NoteAIDialog renders header, tabs, and empty placeholder states', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockService = _MockNoteAIService(
        mockSummary: testSummary,
        mockExplanation: testExplanation,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteAIProvider.overrideWithValue(mockService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NoteAIDialog(
                topicTitle: 'Rust Systems',
                initialNoteContent: '# Rust Systems Notes',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('AI Study Assistant'), findsOneWidget);
      expect(find.text('Topic: Rust Systems'), findsOneWidget);

      // Tabs verification
      expect(find.text('Smart Summarizer'), findsOneWidget);
      expect(find.text('Concept Explainer'), findsOneWidget);

      // Summarizer controls
      expect(find.text('Key Takeaways'), findsOneWidget);
      expect(find.text('Executive Brief'), findsOneWidget);
      expect(find.text('Bullet Points'), findsOneWidget);
      expect(find.text('Cheat Sheet'), findsOneWidget);
      expect(find.byKey(const Key('note_ai_summarize_btn')), findsOneWidget);

      // Initial empty state
      expect(find.text('No summary generated yet'), findsOneWidget);
    });

    testWidgets('Smart Summarizer generates summary, renders markdown, and triggers insert callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockService = _MockNoteAIService(
        mockSummary: testSummary,
        mockExplanation: testExplanation,
      );

      String? insertedText;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteAIProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NoteAIDialog(
                topicTitle: 'Rust Lifetimes',
                initialNoteContent: '# Rust Lifetimes\nBorrow checker rules.',
                onInsertAtTop: (text) => insertedText = text,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Summarize Note button
      await tester.tap(find.byKey(const Key('note_ai_summarize_btn')));
      await tester.pumpAndSettle();

      // Verify metadata header
      expect(find.text('builtin-offline'), findsOneWidget);
      expect(find.text('📝 28 words'), findsOneWidget);
      expect(find.text('⏱️ 0.1 min read'), findsOneWidget);

      // Verify markdown viewer
      expect(find.byKey(const Key('note_ai_summary_viewer')), findsOneWidget);
      expect(find.textContaining('Rust Lifetimes'), findsWidgets);

      // Verify Insert at Top action
      expect(find.byKey(const Key('note_ai_insert_top_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('note_ai_insert_top_btn')));
      await tester.pumpAndSettle();

      expect(insertedText, contains('Key Takeaways: Rust Lifetimes'));
    });

    testWidgets('Concept Explainer generates explanation, renders markdown, and triggers append callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockService = _MockNoteAIService(
        mockSummary: testSummary,
        mockExplanation: testExplanation,
      );

      String? appendedText;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteAIProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: NoteAIDialog(
                topicTitle: 'Raft Consensus',
                onAppendToEnd: (text) => appendedText = text,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Explainer tab
      await tester.tap(find.text('Concept Explainer'));
      await tester.pumpAndSettle();

      // Input concept
      expect(find.byKey(const Key('note_ai_concept_input')), findsOneWidget);

      // Tap Explain Concept button
      await tester.tap(find.byKey(const Key('note_ai_explain_btn')));
      await tester.pumpAndSettle();

      // Verify depth badge
      expect(find.textContaining('Depth:'), findsOneWidget);

      // Verify explanation viewer
      expect(find.byKey(const Key('note_ai_explain_viewer')), findsOneWidget);
      expect(find.textContaining('Raft Consensus'), findsWidgets);

      // Tap Append Explanation to Note button
      expect(find.byKey(const Key('note_ai_append_explain_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('note_ai_append_explain_btn')));
      await tester.pumpAndSettle();

      expect(appendedText, contains('Technical Deep Dive: Raft Consensus'));
    });
  });
}
