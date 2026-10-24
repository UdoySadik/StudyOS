import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/projects/application/projects_provider.dart';
import 'package:studyos/features/projects/domain/project_model.dart';
import 'package:studyos/features/projects/presentation/projects_page.dart';
import 'package:studyos/features/roadmap/application/roadmap_provider.dart';
import 'package:studyos/features/roadmap/domain/roadmap_models.dart';

void main() {
  group('ProjectModel Domain Tests', () {
    test('ProjectModel serializes & deserializes correctly', () {
      final json = {
        'id': 42,
        'roadmap_id': 1,
        'topic_id': 10,
        'title': 'Raft Consensus Engine',
        'description': 'Distributed fault-tolerant consensus implementation',
        'github_url': 'https://github.com/developer/raft-go',
        'live_url': 'https://raft.dev',
        'status': 'in_progress',
        'difficulty': 'advanced',
        'tech_stack': 'Go, gRPC, Protobuf, Docker',
        'created_at': '2026-10-23T12:00:00.000Z',
        'completed_at': null,
        'roadmap_title': 'Distributed Systems',
        'topic_title': 'Consensus Algorithms',
      };

      final project = ProjectModel.fromJson(json);
      expect(project.id, 42);
      expect(project.roadmapId, 1);
      expect(project.topicId, 10);
      expect(project.title, 'Raft Consensus Engine');
      expect(project.description, 'Distributed fault-tolerant consensus implementation');
      expect(project.githubUrl, 'https://github.com/developer/raft-go');
      expect(project.liveUrl, 'https://raft.dev');
      expect(project.status, 'in_progress');
      expect(project.difficulty, 'advanced');
      expect(project.techStack, 'Go, gRPC, Protobuf, Docker');
      expect(project.roadmapTitle, 'Distributed Systems');
      expect(project.topicTitle, 'Consensus Algorithms');

      final techList = project.techStackList;
      expect(techList, ['Go', 'gRPC', 'Protobuf', 'Docker']);

      expect(project.statusLabel, 'In Progress');
      expect(project.difficultyLabel, 'Advanced');
      expect(project.isCompleted, false);

      final exported = project.toJson();
      expect(exported['id'], 42);
      expect(exported['status'], 'in_progress');

      final updated = project.copyWith(status: 'completed', difficulty: 'medium');
      expect(updated.status, 'completed');
      expect(updated.isCompleted, true);
      expect(updated.statusLabel, 'Completed');
      expect(updated.difficulty, 'medium');
      expect(updated.difficultyLabel, 'Medium');
    });

    test('ProjectModel handles optional null fields gracefully', () {
      final json = {
        'id': 1,
        'roadmap_id': 2,
        'title': 'CLI Tool',
      };
      final project = ProjectModel.fromJson(json);
      expect(project.id, 1);
      expect(project.title, 'CLI Tool');
      expect(project.status, 'not_started');
      expect(project.difficulty, 'medium');
      expect(project.techStackList, isEmpty);
      expect(project.githubUrl, isNull);
    });
  });

  group('ProjectsPage Presentation Widget Tests', () {
    testWidgets('ProjectsPage renders header, metrics, search, and project card', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockRoadmaps = [
        RoadmapModel(
          id: 1,
          title: 'Distributed Systems',
          description: 'Advanced distributed syllabus',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final mockProjects = [
        const ProjectModel(
          id: 101,
          roadmapId: 1,
          topicId: 5,
          title: 'StudyOS Async Dispatcher',
          description: 'High throughput local queue engine',
          githubUrl: 'https://github.com/studyos/dispatcher',
          liveUrl: 'https://dispatcher.studyos.dev',
          status: 'in_progress',
          difficulty: 'advanced',
          techStack: 'Python, FastAPI, Redis',
          roadmapTitle: 'Distributed Systems',
          topicTitle: 'Event Queues',
        ),
        const ProjectModel(
          id: 102,
          roadmapId: 1,
          title: 'Markdown Tree Parser',
          description: 'Lexer and parser in Dart',
          githubUrl: 'https://github.com/studyos/md-parser',
          status: 'completed',
          difficulty: 'medium',
          techStack: 'Dart, CLI',
          roadmapTitle: 'Distributed Systems',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roadmapsProvider.overrideWith((ref) async => mockRoadmaps),
            projectsListProvider.overrideWith(() => _MockProjectsListNotifier(mockProjects)),
          ],
          child: const MaterialApp(
            home: ProjectsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Practice Project Tracker'), findsOneWidget);
      expect(find.text('New Project'), findsOneWidget);

      // Check metrics
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Completion Rate'), findsOneWidget);

      // Check project card 1
      expect(find.text('StudyOS Async Dispatcher'), findsOneWidget);
      expect(find.text('High throughput local queue engine'), findsOneWidget);
      expect(find.text('ADVANCED'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('FastAPI'), findsOneWidget);
      expect(find.text('Redis'), findsOneWidget);
      expect(find.text('GitHub Repo'), findsWidgets);
      expect(find.text('Live Demo'), findsOneWidget);

      // Check project card 2
      expect(find.text('Markdown Tree Parser'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
    });

    testWidgets('Tapping GitHub link button copies URL and displays snackbar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockProjects = [
        const ProjectModel(
          id: 1,
          roadmapId: 1,
          title: 'Sample Project',
          githubUrl: 'https://github.com/test/repo',
          status: 'in_progress',
          difficulty: 'beginner',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roadmapsProvider.overrideWith((ref) async => []),
            projectsListProvider.overrideWith(() => _MockProjectsListNotifier(mockProjects)),
          ],
          child: const MaterialApp(
            home: ProjectsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final githubBtn = find.byKey(const Key('project_github_btn_1'));
      expect(githubBtn, findsOneWidget);

      await tester.tap(githubBtn);
      await tester.pump();

      expect(find.text('Copied GitHub Repo link: https://github.com/test/repo'), findsOneWidget);
    });

    testWidgets('Toggling status complete calls notifier', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockNotifier = _MockProjectsListNotifier([
        const ProjectModel(
          id: 99,
          roadmapId: 1,
          title: 'Status Test Project',
          status: 'in_progress',
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roadmapsProvider.overrideWith((ref) async => []),
            projectsListProvider.overrideWith(() => mockNotifier),
          ],
          child: const MaterialApp(
            home: ProjectsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final toggleBtn = find.byKey(const Key('project_toggle_status_99'));
      expect(toggleBtn, findsOneWidget);

      await tester.tap(toggleBtn);
      await tester.pumpAndSettle();

      expect(mockNotifier.statusUpdatedId, 99);
      expect(mockNotifier.updatedStatus, 'completed');
    });

    testWidgets('New Project button opens modal dialog with form fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1366, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockRoadmaps = [
        RoadmapModel(
          id: 1,
          title: 'Master Go Programming',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            roadmapsProvider.overrideWith((ref) async => mockRoadmaps),
            projectsListProvider.overrideWith(() => _MockProjectsListNotifier([])),
          ],
          child: const MaterialApp(
            home: ProjectsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap New Project button
      final newProjBtn = find.byKey(const Key('new_project_button'));
      expect(newProjBtn, findsOneWidget);
      await tester.tap(newProjBtn);
      await tester.pumpAndSettle();

      // Modal dialog should appear
      expect(find.text('Create Practice Project'), findsOneWidget);
      expect(find.byKey(const Key('project_title_input')), findsOneWidget);
      expect(find.byKey(const Key('project_desc_input')), findsOneWidget);
      expect(find.byKey(const Key('project_tech_input')), findsOneWidget);
      expect(find.byKey(const Key('project_github_input')), findsOneWidget);
      expect(find.byKey(const Key('project_live_input')), findsOneWidget);
      expect(find.text('Beginner'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Advanced'), findsOneWidget);
      expect(find.byKey(const Key('project_submit_btn')), findsOneWidget);
    });
  });
}

class _MockProjectsListNotifier extends ProjectsListNotifier {
  final List<ProjectModel> mockItems;
  int? statusUpdatedId;
  String? updatedStatus;

  _MockProjectsListNotifier(this.mockItems);

  @override
  Future<List<ProjectModel>> build() async => mockItems;

  @override
  Future<void> updateStatus(int id, String status) async {
    statusUpdatedId = id;
    updatedStatus = status;
  }

  @override
  Future<void> deleteProject(int id) async {}

  @override
  Future<void> createProject({
    required int roadmapId,
    int? topicId,
    required String title,
    String? description,
    String? githubUrl,
    String? liveUrl,
    String status = 'not_started',
    String difficulty = 'medium',
    String? techStack,
  }) async {}

  @override
  Future<void> updateProject(
    int id, {
    int? roadmapId,
    int? topicId,
    String? title,
    String? description,
    String? githubUrl,
    String? liveUrl,
    String? status,
    String? difficulty,
    String? techStack,
  }) async {}
}
