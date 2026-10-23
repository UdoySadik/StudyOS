import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/resources/application/resources_provider.dart';
import 'package:studyos/features/resources/domain/resource_model.dart';
import 'package:studyos/features/resources/presentation/resource_shelf_dialog.dart';

void main() {
  group('ResourceModel Domain Tests', () {
    test('ResourceModel serializes & deserializes correctly', () {
      final json = {
        'id': 101,
        'topic_id': 5,
        'title': 'Designing Data-Intensive Applications',
        'resource_type': 'book',
        'url': 'https://dataintensive.net',
        'notes': 'Chapters 5, 6, 7 on replication and partitioning',
        'is_completed': false,
        'created_at': '2026-10-23T12:00:00.000Z',
      };

      final model = ResourceModel.fromJson(json);
      expect(model.id, 101);
      expect(model.topicId, 5);
      expect(model.title, 'Designing Data-Intensive Applications');
      expect(model.resourceType, 'book');
      expect(model.url, 'https://dataintensive.net');
      expect(model.notes, 'Chapters 5, 6, 7 on replication and partitioning');
      expect(model.isCompleted, false);
      expect(model.createdAt, isNotNull);

      final exported = model.toJson();
      expect(exported['id'], 101);
      expect(exported['resource_type'], 'book');

      final updated = model.copyWith(isCompleted: true, title: 'DDIA');
      expect(updated.isCompleted, true);
      expect(updated.title, 'DDIA');
      expect(updated.id, 101);
    });
  });

  group('ResourceShelfDialog Presentation Widget Tests', () {
    testWidgets('ResourceShelfDialog renders header, progress, and resource items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockResources = [
        ResourceModel(
          id: 1,
          topicId: 10,
          title: 'Database Internals Book',
          resourceType: 'book',
          url: 'https://www.databass.dev',
          notes: 'Storage engine B-Tree chapters',
          isCompleted: true,
        ),
        ResourceModel(
          id: 2,
          topicId: 10,
          title: 'CMU 15-445 Buffer Pool Video',
          resourceType: 'video',
          url: 'https://youtube.com/watch?v=15445',
          notes: 'LRU-K eviction algorithm',
          isCompleted: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicResourcesProvider.overrideWith(() => _MockTopicResourcesNotifier(mockResources)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ResourceShelfDialog(
                topicId: 10,
                topicTitle: 'Storage Engines',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Learning Resource Shelf'), findsOneWidget);
      expect(find.text('Storage Engines'), findsOneWidget);

      // Check progress
      expect(find.text('1 of 2 resources completed'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      // Check resource items
      expect(find.text('Database Internals Book'), findsOneWidget);
      expect(find.text('BOOK'), findsOneWidget);
      expect(find.text('CMU 15-445 Buffer Pool Video'), findsOneWidget);
      expect(find.text('VIDEO'), findsOneWidget);

      // Check URLs and notes
      expect(find.text('https://www.databass.dev'), findsOneWidget);
      expect(find.text('Storage engine B-Tree chapters'), findsOneWidget);
    });

    testWidgets('ResourceShelfDialog expands Add Resource form and renders chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockNotifier = _MockTopicResourcesNotifier([]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            topicResourcesProvider.overrideWith(() => mockNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ResourceShelfDialog(
                topicId: 10,
                topicTitle: 'Storage Engines',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check empty state
      expect(find.text('Resource shelf is empty'), findsOneWidget);

      // Tap Add First Resource
      await tester.tap(find.text('Add First Resource'));
      await tester.pumpAndSettle();

      // Form should be visible with chips
      expect(find.text('New Learning Resource'), findsOneWidget);
      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Article'), findsOneWidget);
      expect(find.text('Course'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('Save to Shelf'), findsOneWidget);

      // Enter title and tap save
      await tester.enterText(find.byType(TextField).first, 'Clean Code');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save to Shelf'));
      await tester.pumpAndSettle();

      expect(mockNotifier.addedTitles, contains('Clean Code'));
    });
  });
}

class _MockTopicResourcesNotifier extends TopicResourcesNotifier {
  final List<ResourceModel> mockItems;
  final List<String> addedTitles = [];

  _MockTopicResourcesNotifier(this.mockItems);

  @override
  Future<List<ResourceModel>> build(int topicId) async => mockItems;

  @override
  Future<void> addResource({
    required String title,
    String resourceType = 'article',
    String? url,
    String? notes,
  }) async {
    addedTitles.add(title);
  }

  @override
  Future<void> toggleComplete(int resourceId, bool isCompleted) async {}

  @override
  Future<void> deleteResource(int resourceId) async {}
}
