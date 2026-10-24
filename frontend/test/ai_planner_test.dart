import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/ai_planner/application/ai_planner_provider.dart';
import 'package:studyos/features/ai_planner/domain/study_plan_model.dart';
import 'package:studyos/features/ai_planner/presentation/ai_planner_page.dart';
import 'package:studyos/features/roadmap/application/roadmap_provider.dart';

void main() {
  group('StudyPlanModel Domain Tests', () {
    test('OllamaStatusModel deserializes correctly', () {
      final json = {
        'connected': true,
        'endpoint': 'http://127.0.0.1:11434',
        'models': ['llama3.2', 'mistral', 'deepseek-r1'],
      };
      final status = OllamaStatusModel.fromJson(json);
      expect(status.connected, true);
      expect(status.endpoint, 'http://127.0.0.1:11434');
      expect(status.models, ['llama3.2', 'mistral', 'deepseek-r1']);
    });

    test('StudyPlanModel serializes & deserializes correctly', () {
      final json = {
        'id': 10,
        'title': 'Rust Systems — 4W Plan',
        'subject': 'Rust Systems Programming',
        'proficiency': 'advanced',
        'hours_per_week': 15,
        'target_weeks': 4,
        'model_used': 'builtin-offline',
        'plan_markdown': '# Rust Systems Mastery\n\n## Phase 1: Memory Safety',
        'structured_data': {
          'title': 'Rust Systems',
          'phases': [
            {'title': 'Phase 1: Memory', 'topics': ['Ownership', 'Lifetimes']},
          ],
        },
        'roadmap_id': null,
        'roadmap_title': null,
        'created_at': '2026-10-24T12:00:00.000Z',
      };

      final plan = StudyPlanModel.fromJson(json);
      expect(plan.id, 10);
      expect(plan.title, 'Rust Systems — 4W Plan');
      expect(plan.subject, 'Rust Systems Programming');
      expect(plan.proficiency, 'advanced');
      expect(plan.hoursPerWeek, 15);
      expect(plan.targetWeeks, 4);
      expect(plan.totalHours, 60);
      expect(plan.isImported, false);
      expect(plan.structuredData, isNotNull);

      final exported = plan.toJson();
      expect(exported['id'], 10);
      expect(exported['target_weeks'], 4);

      final updated = plan.copyWith(roadmapId: 5, roadmapTitle: 'Rust Syllabus');
      expect(updated.isImported, true);
      expect(updated.roadmapId, 5);
      expect(updated.roadmapTitle, 'Rust Syllabus');
    });
  });

  group('AIPlannerPage Presentation Widget Tests', () {
    testWidgets('AIPlannerPage renders header, offline notice, parameters form, and empty viewer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const mockOllama = OllamaStatusModel(
        connected: false,
        endpoint: 'http://127.0.0.1:11434',
        models: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ollamaStatusProvider.overrideWith((ref) async => mockOllama),
            studyPlansListProvider.overrideWith(() => _MockStudyPlansNotifier([])),
            roadmapsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: AIPlannerPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Offline LLM Study Planner'), findsOneWidget);

      // Check offline notice
      expect(find.text('Ollama: Offline'), findsOneWidget);

      // Check form fields
      expect(find.byKey(const Key('ai_planner_subject_input')), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.byKey(const Key('ai_planner_generate_btn')), findsOneWidget);

      // Check empty viewer
      expect(find.text('No Study Plan Selected'), findsOneWidget);
    });

    testWidgets('AIPlannerPage renders connected Ollama status and selected plan markdown', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const mockOllama = OllamaStatusModel(
        connected: true,
        endpoint: 'http://127.0.0.1:11434',
        models: ['llama3.2', 'mistral'],
      );

      const mockPlan = StudyPlanModel(
        id: 77,
        title: 'Distributed Systems — 4W Plan',
        subject: 'Distributed Systems',
        proficiency: 'advanced',
        hoursPerWeek: 12,
        targetWeeks: 4,
        modelUsed: 'llama3.2',
        planMarkdown: '# Distributed Systems Syllabus\n\n- [ ] Raft Consensus\n- [ ] Paxos',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ollamaStatusProvider.overrideWith((ref) async => mockOllama),
            studyPlansListProvider.overrideWith(() => _MockStudyPlansNotifier([mockPlan])),
            roadmapsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: AIPlannerPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Ollama connected
      expect(find.text('Ollama: Connected'), findsOneWidget);
      expect(find.text('llama3.2'), findsWidgets);

      // Check plan viewer
      expect(find.text('Distributed Systems — 4W Plan'), findsWidgets);
      expect(find.text('ADVANCED'), findsOneWidget);
      expect(find.byKey(const Key('ai_plan_markdown_viewer')), findsOneWidget);
      expect(find.byKey(const Key('ai_plan_import_roadmap_btn')), findsOneWidget);
      expect(find.byKey(const Key('ai_plan_copy_btn')), findsOneWidget);
    });

    testWidgets('Tapping Convert to Roadmap calls importRoadmap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const mockPlan = StudyPlanModel(
        id: 88,
        title: 'Kubernetes Deep Dive',
        subject: 'Kubernetes',
        proficiency: 'intermediate',
        hoursPerWeek: 10,
        targetWeeks: 4,
        modelUsed: 'builtin-offline',
        planMarkdown: '# Kubernetes Deep Dive\n\n## Phase 1: Architecture',
      );

      final mockNotifier = _MockStudyPlansNotifier([mockPlan]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ollamaStatusProvider.overrideWith((ref) async => const OllamaStatusModel(connected: false, endpoint: '', models: [])),
            studyPlansListProvider.overrideWith(() => mockNotifier),
            roadmapsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: AIPlannerPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final importBtn = find.byKey(const Key('ai_plan_import_roadmap_btn'));
      expect(importBtn, findsOneWidget);

      await tester.tap(importBtn);
      await tester.pumpAndSettle();

      expect(mockNotifier.importedPlanId, 88);
    });
  });
}

class _MockStudyPlansNotifier extends StudyPlansListNotifier {
  final List<StudyPlanModel> mockPlans;
  int? importedPlanId;
  int? deletedPlanId;

  _MockStudyPlansNotifier(this.mockPlans);

  @override
  Future<List<StudyPlanModel>> build() async => mockPlans;

  @override
  Future<void> importRoadmap(int planId) async {
    importedPlanId = planId;
  }

  @override
  Future<void> deletePlan(int planId) async {
    deletedPlanId = planId;
  }

  @override
  Future<StudyPlanModel> generatePlan({
    required String subject,
    String proficiency = 'intermediate',
    int hoursPerWeek = 10,
    int targetWeeks = 4,
    String? focusArea,
    String? customInstructions,
    String? model,
    int? roadmapId,
  }) async {
    return mockPlans.first;
  }
}
