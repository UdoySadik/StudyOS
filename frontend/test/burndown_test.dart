import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/analytics/application/burndown_provider.dart';
import 'package:studyos/features/analytics/domain/burndown_model.dart';
import 'package:studyos/features/analytics/presentation/burndown_velocity_card.dart';

void main() {
  group('BurndownModel Domain Tests', () {
    test('PhaseBurndownModel serializes & deserializes correctly', () {
      final json = {
        'phase_id': 10,
        'phase_title': 'Core Flutter Basics',
        'order_index': 0,
        'total_topics': 10,
        'completed_topics': 6,
        'remaining_topics': 4,
        'progress_percent': 60.0,
        'estimated_days_to_complete': 4.0,
      };

      final phase = PhaseBurndownModel.fromJson(json);
      expect(phase.phaseId, 10);
      expect(phase.phaseTitle, 'Core Flutter Basics');
      expect(phase.orderIndex, 0);
      expect(phase.totalTopics, 10);
      expect(phase.completedTopics, 6);
      expect(phase.remainingTopics, 4);
      expect(phase.progressPercent, 60.0);
      expect(phase.estimatedDaysToComplete, 4.0);

      final exported = phase.toJson();
      expect(exported['phase_id'], 10);
      expect(exported['phase_title'], 'Core Flutter Basics');
      expect(exported['progress_percent'], 60.0);
    });

    test('DailyVelocityModel serializes & deserializes correctly', () {
      final json = {
        'date': '2026-10-22',
        'day_label': 'Thu',
        'topics_completed': 3,
        'study_seconds': 5400,
      };

      final velocity = DailyVelocityModel.fromJson(json);
      expect(velocity.date, '2026-10-22');
      expect(velocity.dayLabel, 'Thu');
      expect(velocity.topicsCompleted, 3);
      expect(velocity.studySeconds, 5400);

      final exported = velocity.toJson();
      expect(exported['date'], '2026-10-22');
      expect(exported['topics_completed'], 3);
    });

    test('RoadmapBurndownModel parses complete response correctly', () {
      final json = {
        'roadmap_id': 1,
        'roadmap_title': 'Complete Flutter Roadmap',
        'total_topics': 20,
        'completed_topics': 12,
        'remaining_topics': 8,
        'progress_percent': 60.0,
        'target_date': '2026-11-15',
        'days_remaining': 24,
        'required_velocity': 0.33,
        'current_velocity_7d': 1.14,
        'current_study_hours_7d': 14.5,
        'status': 'ahead',
        'status_label': 'Ahead of Schedule',
        'projected_completion_date': '2026-10-29',
        'phases': [
          {
            'phase_id': 101,
            'phase_title': 'Basics',
            'order_index': 0,
            'total_topics': 10,
            'completed_topics': 10,
            'remaining_topics': 0,
            'progress_percent': 100.0,
            'estimated_days_to_complete': 0.0,
          },
          {
            'phase_id': 102,
            'phase_title': 'Advanced State',
            'order_index': 1,
            'total_topics': 10,
            'completed_topics': 2,
            'remaining_topics': 8,
            'progress_percent': 20.0,
            'estimated_days_to_complete': 7.0,
          },
        ],
        'recent_velocity': [
          {'date': '2026-10-16', 'day_label': 'Fri', 'topics_completed': 1, 'study_seconds': 3600},
          {'date': '2026-10-17', 'day_label': 'Sat', 'topics_completed': 0, 'study_seconds': 0},
          {'date': '2026-10-18', 'day_label': 'Sun', 'topics_completed': 2, 'study_seconds': 7200},
          {'date': '2026-10-19', 'day_label': 'Mon', 'topics_completed': 1, 'study_seconds': 3600},
          {'date': '2026-10-20', 'day_label': 'Tue', 'topics_completed': 2, 'study_seconds': 5400},
          {'date': '2026-10-21', 'day_label': 'Wed', 'topics_completed': 1, 'study_seconds': 1800},
          {'date': '2026-10-22', 'day_label': 'Thu', 'topics_completed': 1, 'study_seconds': 3600},
        ],
      };

      final model = RoadmapBurndownModel.fromJson(json);
      expect(model.roadmapId, 1);
      expect(model.roadmapTitle, 'Complete Flutter Roadmap');
      expect(model.totalTopics, 20);
      expect(model.completedTopics, 12);
      expect(model.remainingTopics, 8);
      expect(model.status, 'ahead');
      expect(model.statusLabel, 'Ahead of Schedule');
      expect(model.phases.length, 2);
      expect(model.recentVelocity.length, 7);

      final exported = model.toJson();
      expect(exported['roadmap_id'], 1);
      expect(exported['phases'].length, 2);
    });
  });

  group('BurndownVelocityCard Presentation Widget Tests', () {
    testWidgets('BurndownVelocityCard renders phases, velocity metrics, and status badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockBurndown = RoadmapBurndownModel(
        roadmapId: 1,
        roadmapTitle: 'Mobile Dev Track',
        totalTopics: 15,
        completedTopics: 9,
        remainingTopics: 6,
        progressPercent: 60.0,
        targetDate: '2026-11-20',
        daysRemaining: 29,
        requiredVelocity: 0.21,
        currentVelocity7d: 1.29,
        currentStudyHours7d: 12.0,
        status: 'ahead',
        statusLabel: 'Ahead of Schedule',
        projectedCompletionDate: '2026-10-27',
        phases: [
          PhaseBurndownModel(
            phaseId: 1,
            phaseTitle: 'Dart Fundamentals',
            orderIndex: 0,
            totalTopics: 5,
            completedTopics: 5,
            remainingTopics: 0,
            progressPercent: 100.0,
            estimatedDaysToComplete: 0.0,
          ),
          PhaseBurndownModel(
            phaseId: 2,
            phaseTitle: 'Flutter Widgets',
            orderIndex: 1,
            totalTopics: 10,
            completedTopics: 4,
            remainingTopics: 6,
            progressPercent: 40.0,
            estimatedDaysToComplete: 4.7,
          ),
        ],
        recentVelocity: [
          DailyVelocityModel(date: '2026-10-16', dayLabel: 'Fri', topicsCompleted: 1, studySeconds: 3600),
          DailyVelocityModel(date: '2026-10-17', dayLabel: 'Sat', topicsCompleted: 0, studySeconds: 0),
          DailyVelocityModel(date: '2026-10-18', dayLabel: 'Sun', topicsCompleted: 2, studySeconds: 7200),
          DailyVelocityModel(date: '2026-10-19', dayLabel: 'Mon', topicsCompleted: 1, studySeconds: 3600),
          DailyVelocityModel(date: '2026-10-20', dayLabel: 'Tue', topicsCompleted: 2, studySeconds: 5400),
          DailyVelocityModel(date: '2026-10-21', dayLabel: 'Wed', topicsCompleted: 2, studySeconds: 3600),
          DailyVelocityModel(date: '2026-10-22', dayLabel: 'Thu', topicsCompleted: 1, studySeconds: 3600),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            burndownProvider.overrideWith(() => _MockBurndownNotifier(mockBurndown)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BurndownVelocityCard(roadmapId: 1),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and status badge
      expect(find.text('Phase Burndown & Learning Velocity'), findsOneWidget);
      expect(find.text('Ahead of Schedule'), findsOneWidget);

      // Check Phase Breakdown
      expect(find.text('Phase Breakdown'), findsOneWidget);
      expect(find.text('9/15 Topics (60.0%)'), findsOneWidget);
      expect(find.text('1. Dart Fundamentals'), findsOneWidget);
      expect(find.text('5/5 done'), findsOneWidget);
      expect(find.text('2. Flutter Widgets'), findsOneWidget);
      expect(find.text('4/10 done'), findsOneWidget);
      expect(find.text('~4.7 days to complete at current pace'), findsOneWidget);

      // Check Learning Velocity section
      expect(find.text('Learning Velocity & Trajectory'), findsOneWidget);
      expect(find.text('Current Pace'), findsOneWidget);
      expect(find.text('1.29'), findsOneWidget);
      expect(find.text('Required Pace'), findsOneWidget);
      expect(find.text('0.21'), findsOneWidget);
      expect(find.text('Projected Finish'), findsOneWidget);

      // Check 7-day velocity chart
      expect(find.text('7-Day Topics Completed'), findsOneWidget);
    });

    testWidgets('BurndownVelocityCard handles empty phases gracefully', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final emptyBurndown = RoadmapBurndownModel(
        roadmapId: 2,
        roadmapTitle: 'Empty Roadmap',
        totalTopics: 0,
        completedTopics: 0,
        remainingTopics: 0,
        progressPercent: 0.0,
        targetDate: null,
        daysRemaining: null,
        requiredVelocity: 0.0,
        currentVelocity7d: 0.0,
        currentStudyHours7d: 0.0,
        status: 'no_goal',
        statusLabel: 'No Deadline Set',
        projectedCompletionDate: null,
        phases: [],
        recentVelocity: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            burndownProvider.overrideWith(() => _MockBurndownNotifier(emptyBurndown)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: BurndownVelocityCard(roadmapId: 2),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Phase Burndown & Learning Velocity'), findsOneWidget);
      expect(find.text('No Deadline Set'), findsOneWidget);
      expect(find.text('No phases defined yet in this roadmap.'), findsOneWidget);
    });
  });
}

class _MockBurndownNotifier extends BurndownNotifier {
  final RoadmapBurndownModel mockData;
  _MockBurndownNotifier(this.mockData);

  @override
  Future<RoadmapBurndownModel> build(int roadmapId) async => mockData;
}
