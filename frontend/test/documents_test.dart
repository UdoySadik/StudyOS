import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/documents/application/documents_provider.dart';
import 'package:studyos/features/documents/domain/document_models.dart';
import 'package:studyos/features/documents/presentation/add_document_dialog.dart';
import 'package:studyos/features/documents/presentation/document_hub_page.dart';

void main() {
  group('Document Intelligence Domain Models Tests', () {
    test('DocumentChunkModel serializes and deserializes correctly', () {
      final json = {
        'id': 101,
        'document_id': 12,
        'chunk_index': 0,
        'page_number': 2,
        'content': 'Leader election requires randomized timeouts.',
        'word_count': 6,
        'created_at': '2026-10-25T12:00:00Z',
      };

      final chunk = DocumentChunkModel.fromJson(json);
      expect(chunk.id, 101);
      expect(chunk.documentId, 12);
      expect(chunk.chunkIndex, 0);
      expect(chunk.pageNumber, 2);
      expect(chunk.content, contains('randomized timeouts'));
      expect(chunk.wordCount, 6);

      final exported = chunk.toJson();
      expect(exported['id'], 101);
      expect(exported['chunk_index'], 0);
      expect(exported['page_number'], 2);
    });

    test('DocumentModel serializes and deserializes correctly', () {
      final json = {
        'id': 12,
        'title': 'Raft Consensus Paper',
        'doc_type': 'paper',
        'file_path': '/papers/raft.pdf',
        'total_pages': 18,
        'total_chunks': 32,
        'topic_id': 4,
        'roadmap_id': 1,
        'topic_title': 'Consensus Protocols',
        'roadmap_title': 'Distributed Systems',
        'created_at': '2026-10-25T12:00:00Z',
        'chunks': [
          {
            'id': 101,
            'document_id': 12,
            'chunk_index': 0,
            'page_number': 1,
            'content': 'Raft is a consensus algorithm for managing replicated logs.',
            'word_count': 9,
          }
        ],
      };

      final doc = DocumentModel.fromJson(json);
      expect(doc.id, 12);
      expect(doc.title, 'Raft Consensus Paper');
      expect(doc.docType, 'paper');
      expect(doc.totalPages, 18);
      expect(doc.totalChunks, 32);
      expect(doc.chunks.length, 1);
      expect(doc.chunks.first.content, contains('replicated logs'));

      final exported = doc.toJson();
      expect(exported['title'], 'Raft Consensus Paper');
      expect(exported['total_chunks'], 32);
    });

    test('CitationModel serializes and deserializes correctly', () {
      final json = {
        'document_id': 12,
        'document_title': 'Raft Consensus Paper',
        'chunk_index': 3,
        'page_number': 2,
        'snippet': 'election timeouts are randomized from a fixed interval...',
        'relevance_score': 0.88,
      };

      final citation = CitationModel.fromJson(json);
      expect(citation.documentId, 12);
      expect(citation.documentTitle, 'Raft Consensus Paper');
      expect(citation.pageNumber, 2);
      expect(citation.snippet, contains('randomized'));
      expect(citation.relevanceScore, 0.88);

      final exported = citation.toJson();
      expect(exported['document_id'], 12);
      expect(exported['relevance_score'], 0.88);
    });

    test('RAGQueryResult serializes and deserializes correctly', () {
      final json = {
        'query': 'How are split votes avoided in Raft?',
        'answer_markdown': '### 📖 Answer\nSplit votes are avoided using randomized election timeouts.',
        'model_used': 'builtin-offline',
        'retrieval_count': 1,
        'citations': [
          {
            'document_id': 12,
            'document_title': 'Raft Paper',
            'chunk_index': 1,
            'page_number': 2,
            'snippet': 'randomized election timeouts prevent split votes',
            'relevance_score': 0.92,
          }
        ],
      };

      final result = RAGQueryResult.fromJson(json);
      expect(result.query, contains('split votes'));
      expect(result.answerMarkdown, contains('randomized election timeouts'));
      expect(result.modelUsed, 'builtin-offline');
      expect(result.retrievalCount, 1);
      expect(result.citations.length, 1);
      expect(result.citations.first.relevanceScore, 0.92);

      final exported = result.toJson();
      expect(exported['query'], contains('split votes'));
      expect(exported['model_used'], 'builtin-offline');
    });
  });

  group('AddDocumentDialog Widget Tests', () {
    testWidgets('renders all form fields, options, and validates empty input', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddDocumentDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify title, inputs, and options exist
      expect(find.text('Index Study Document for RAG'), findsOneWidget);
      expect(find.byKey(const Key('add_document_title_field')), findsOneWidget);
      expect(find.byKey(const Key('add_document_content_field')), findsOneWidget);
      expect(find.byKey(const Key('add_document_submit_btn')), findsOneWidget);
      expect(find.text('Textbook'), findsOneWidget);
      expect(find.text('Paper / PDF'), findsOneWidget);
      expect(find.text('Documentation'), findsOneWidget);

      // Tap submit with empty fields -> shows validation errors
      await tester.tap(find.byKey(const Key('add_document_submit_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter document title'), findsOneWidget);
    });

    testWidgets('switches document type selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddDocumentDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Paper / PDF' option
      await tester.tap(find.text('Paper / PDF'));
      await tester.pumpAndSettle();

      expect(find.text('Paper / PDF'), findsOneWidget);
    });
  });

  group('DocumentHubPage Widget Tests', () {
    final sampleDocs = [
      const DocumentModel(
        id: 1,
        title: 'Designing Data-Intensive Applications: Chapter 5',
        docType: 'textbook',
        totalPages: 12,
        totalChunks: 8,
        chunks: [
          DocumentChunkModel(
            id: 11,
            documentId: 1,
            chunkIndex: 0,
            pageNumber: 1,
            content: 'Replication means keeping a copy of the same data across multiple machines.',
            wordCount: 12,
          ),
        ],
      ),
      const DocumentModel(
        id: 2,
        title: 'Raft Consensus Algorithm Paper',
        docType: 'paper',
        totalPages: 18,
        totalChunks: 14,
      ),
    ];

    testWidgets('renders DocumentHubPage header, shelf items, and RAG placeholder', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentsNotifierProvider.overrideWith(
              () => _MockDocumentsNotifier(sampleDocs),
            ),
          ],
          child: const MaterialApp(
            home: DocumentHubPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Document Intelligence & RAG Shelf'), findsOneWidget);
      expect(find.text('Offline RAG Active'), findsOneWidget);
      expect(find.byKey(const Key('index_document_button')), findsOneWidget);

      // Verify Documents in Shelf
      expect(find.text('Designing Data-Intensive Applications: Chapter 5'), findsOneWidget);
      expect(find.text('Raft Consensus Algorithm Paper'), findsOneWidget);
      expect(find.text('TEXTBOOK'), findsOneWidget);
      expect(find.text('PAPER'), findsOneWidget);

      // Verify RAG Assistant Tab
      expect(find.text('RAG Q&A Assistant'), findsOneWidget);
      expect(find.text('Document Chunks Inspector'), findsOneWidget);
      expect(find.byKey(const Key('rag_query_input_field')), findsOneWidget);
      expect(find.byKey(const Key('rag_ask_button')), findsOneWidget);
      expect(find.text('Ask Any Question Across Your Study Documents'), findsOneWidget);
    });

    testWidgets('displays RAG synthesized answer and citation card when query completes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      const mockResult = RAGQueryResult(
        query: 'What is synchronous replication?',
        answerMarkdown: '### 📖 Answer\nIn synchronous replication, the leader waits until followers confirm write completion.',
        modelUsed: 'builtin-offline',
        retrievalCount: 1,
        citations: [
          CitationModel(
            documentId: 1,
            documentTitle: 'Designing Data-Intensive Applications: Chapter 5',
            chunkIndex: 1,
            pageNumber: 3,
            snippet: 'Synchronous replication waits for follower confirmation before notifying client.',
            relevanceScore: 0.94,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          documentsNotifierProvider.overrideWith(
            () => _MockDocumentsNotifier(sampleDocs),
          ),
          ragNotifierProvider.overrideWith(
            (ref) => _MockRAGNotifier(const RAGState(result: mockResult)),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DocumentHubPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify synthesized answer displayed
      expect(find.text('SYNTHESIZED ANSWER'), findsOneWidget);
      expect(find.text('What is synchronous replication?'), findsOneWidget);
      expect(find.textContaining('synchronous replication, the leader waits'), findsOneWidget);

      // Verify citation card
      expect(find.textContaining('Supporting Evidence & Citations'), findsOneWidget);
      expect(find.text('94% Relevance'), findsOneWidget);
      expect(find.textContaining('Designing Data-Intensive Applications'), findsWidgets);
    });

    testWidgets('switches to Document Chunks Inspector tab', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentsNotifierProvider.overrideWith(
              () => _MockDocumentsNotifier(sampleDocs),
            ),
          ],
          child: const MaterialApp(
            home: DocumentHubPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tab 2
      await tester.tap(find.text('Document Chunks Inspector'));
      await tester.pumpAndSettle();

      expect(find.text('Select a Document to Inspect Chunks'), findsOneWidget);
    });
  });
}

class _MockDocumentsNotifier extends DocumentsNotifier {
  final List<DocumentModel> initialDocs;
  _MockDocumentsNotifier(this.initialDocs);

  @override
  Future<List<DocumentModel>> build() async {
    return initialDocs;
  }
}

class _MockRAGNotifier extends RAGNotifier {
  _MockRAGNotifier(RAGState initialState) {
    state = initialState;
  }
}
