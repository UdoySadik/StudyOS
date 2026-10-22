import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/analytics/application/streak_provider.dart';
import 'package:studyos/features/analytics/domain/streak_model.dart';
import 'package:studyos/features/analytics/presentation/streak_card.dart';
import 'package:go_router/go_router.dart';
import 'package:studyos/shared/widgets/app_shell.dart';

void main() {
  group('StreakModel Domain Tests', () {
    test('StreakSummaryModel and DayConsistencyModel serialize & deserialize correctly', () {
      final json = {
        'current_streak': 4,
        'longest_streak': 10,
        'total_active_days': 25,
        'is_active_today': true,
        'weekly_consistency': [
          {
            'date': '2026-10-19',
            'day_label': 'Mon',
            'is_active': true,
            'study_seconds': 3600,
            'completed_blocks': 2,
            'is_today': false,
          },
          {
            'date': '2026-10-20',
            'day_label': 'Tue',
            'is_active': true,
            'study_seconds': 5400,
            'completed_blocks': 1,
            'is_today': false,
          },
          {
            'date': '2026-10-21',
            'day_label': 'Wed',
            'is_active': true,
            'study_seconds': 1800,
            'completed_blocks': 1,
            'is_today': false,
          },
          {
            'date': '2026-10-22',
            'day_label': 'Thu',
            'is_active': true,
            'study_seconds': 2400,
            'completed_blocks': 1,
            'is_today': true,
          },
          {
            'date': '2026-10-23',
            'day_label': 'Fri',
            'is_active': false,
            'study_seconds': 0,
            'completed_blocks': 0,
            'is_today': false,
          },
          {
            'date': '2026-10-24',
            'day_label': 'Sat',
            'is_active': false,
            'study_seconds': 0,
            'completed_blocks': 0,
            'is_today': false,
          },
          {
            'date': '2026-10-25',
            'day_label': 'Sun',
            'is_active': false,
            'study_seconds': 0,
            'completed_blocks': 0,
            'is_today': false,
          },
        ],
        'active_dates_last_30_days': ['2026-10-19', '2026-10-20', '2026-10-21', '2026-10-22'],
      };

      final model = StreakSummaryModel.fromJson(json);

      expect(model.currentStreak, 4);
      expect(model.longestStreak, 10);
      expect(model.totalActiveDays, 25);
      expect(model.isActiveToday, true);
      expect(model.weeklyConsistency.length, 7);
      expect(model.weeklyConsistency[0].dayLabel, 'Mon');
      expect(model.weeklyConsistency[0].isActive, true);
      expect(model.weeklyConsistency[0].studySeconds, 3600);
      expect(model.weeklyConsistency[3].isToday, true);
      expect(model.activeDatesLast30Days.length, 4);

      final exported = model.toJson();
      expect(exported['current_streak'], 4);
      expect(exported['longest_streak'], 10);
    });
  });

  group('StreakPresentation Widget Tests', () {
    testWidgets('StreakConsistencyCard renders active streak, badges, and weekly strip', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockSummary = StreakSummaryModel(
        currentStreak: 5,
        longestStreak: 12,
        totalActiveDays: 30,
        isActiveToday: true,
        weeklyConsistency: [
          DayConsistencyModel(
            date: '2026-10-19',
            dayLabel: 'Mon',
            isActive: true,
            studySeconds: 3600,
            completedBlocks: 1,
            isToday: false,
          ),
          DayConsistencyModel(
            date: '2026-10-20',
            dayLabel: 'Tue',
            isActive: true,
            studySeconds: 1800,
            completedBlocks: 1,
            isToday: false,
          ),
          DayConsistencyModel(
            date: '2026-10-21',
            dayLabel: 'Wed',
            isActive: true,
            studySeconds: 7200,
            completedBlocks: 2,
            isToday: false,
          ),
          DayConsistencyModel(
            date: '2026-10-22',
            dayLabel: 'Thu',
            isActive: true,
            studySeconds: 3600,
            completedBlocks: 1,
            isToday: true,
          ),
          DayConsistencyModel(
            date: '2026-10-23',
            dayLabel: 'Fri',
            isActive: false,
            studySeconds: 0,
            completedBlocks: 0,
            isToday: false,
          ),
          DayConsistencyModel(
            date: '2026-10-24',
            dayLabel: 'Sat',
            isActive: false,
            studySeconds: 0,
            completedBlocks: 0,
            isToday: false,
          ),
          DayConsistencyModel(
            date: '2026-10-25',
            dayLabel: 'Sun',
            isActive: false,
            studySeconds: 0,
            completedBlocks: 0,
            isToday: false,
          ),
        ],
        activeDatesLast30Days: ['2026-10-19', '2026-10-20', '2026-10-21', '2026-10-22'],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            streakProvider.overrideWith(() => _MockStreakNotifier(mockSummary)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StreakConsistencyCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check title & badge
      expect(find.text('5 Day Study Streak!'), findsOneWidget);
      expect(find.text('ACTIVE TODAY'), findsOneWidget);
      expect(find.text('Best: 12 days'), findsOneWidget);
      expect(find.text('30 Total Days'), findsOneWidget);

      // Check weekly days
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('StreakConsistencyCard renders zero-streak state with encouragement', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final zeroSummary = StreakSummaryModel(
        currentStreak: 0,
        longestStreak: 0,
        totalActiveDays: 0,
        isActiveToday: false,
        weeklyConsistency: [
          DayConsistencyModel(
            date: '2026-10-22',
            dayLabel: 'Thu',
            isActive: false,
            studySeconds: 0,
            completedBlocks: 0,
            isToday: true,
          ),
        ],
        activeDatesLast30Days: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            streakProvider.overrideWith(() => _MockStreakNotifier(zeroSummary)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StreakConsistencyCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Start Your Study Streak!'), findsOneWidget);
      expect(find.text('ACTIVE TODAY'), findsNothing);
      expect(find.text('Best: 0 days'), findsOneWidget);
      expect(find.text('0 Total Days'), findsOneWidget);
    });

    testWidgets('AppShell sidebar shows streak counter badge', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockSummary = StreakSummaryModel(
        currentStreak: 7,
        longestStreak: 15,
        totalActiveDays: 45,
        isActiveToday: true,
        weeklyConsistency: [],
        activeDatesLast30Days: [],
      );

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => const AppShell(
              child: Text('Dashboard Content'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            streakProvider.overrideWith(() => _MockStreakNotifier(mockSummary)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('StudyOS'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });
  });
}

class _MockStreakNotifier extends StreakNotifier {
  final StreakSummaryModel mockSummary;
  _MockStreakNotifier(this.mockSummary);

  @override
  Future<StreakSummaryModel> build() async => mockSummary;
}
