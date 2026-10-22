import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/schedule/application/calendar_provider.dart';
import 'package:studyos/features/schedule/application/schedule_provider.dart';
import 'package:studyos/features/schedule/domain/calendar_model.dart';
import 'package:studyos/features/schedule/domain/schedule_model.dart';
import 'package:studyos/features/schedule/presentation/calendar_view.dart';
import 'package:studyos/features/schedule/presentation/schedule_page.dart';

void main() {
  group('CalendarDomainModel Tests', () {
    test('CalendarMonthEvents deserializes correctly from json and filters by date', () {
      final json = {
        'year': 2026,
        'month': 10,
        'goals': [
          {
            'id': 101,
            'roadmap_id': 1,
            'roadmap_title': 'Kubernetes Masterclass',
            'target_date': '2026-10-25',
          },
          {
            'id': 102,
            'roadmap_id': 2,
            'roadmap_title': 'Flutter Architecture',
            'target_date': '2026-10-31',
          }
        ],
        'schedule_blocks': [
          {
            'id': 201,
            'title': 'State Management Deep Dive',
            'scheduled_date': '2026-10-25',
            'start_time': '10:00',
            'end_time': '11:30',
            'is_completed': true,
          },
          {
            'id': 202,
            'title': 'Widget Testing',
            'scheduled_date': '2026-10-26',
            'start_time': '14:00',
            'end_time': '15:00',
            'is_completed': false,
          }
        ],
        'study_sessions': [
          {
            'id': 301,
            'topic_id': 5,
            'topic_title': 'Riverpod Notifiers',
            'logged_date': '2026-10-25',
            'duration_seconds': 3600,
          },
          {
            'id': 302,
            'topic_id': 5,
            'topic_title': 'Riverpod Scopes',
            'logged_date': '2026-10-25',
            'duration_seconds': 1800,
          }
        ]
      };

      final events = CalendarMonthEvents.fromJson(json);

      expect(events.year, 2026);
      expect(events.month, 10);
      expect(events.goals.length, 2);
      expect(events.scheduleBlocks.length, 2);
      expect(events.studySessions.length, 2);

      // Verify date filtering
      final oct25Goals = events.goalsForDate('2026-10-25');
      expect(oct25Goals.length, 1);
      expect(oct25Goals.first.roadmapTitle, 'Kubernetes Masterclass');

      final oct25Blocks = events.blocksForDate('2026-10-25');
      expect(oct25Blocks.length, 1);
      expect(oct25Blocks.first.isCompleted, true);

      final oct25Sessions = events.sessionsForDate('2026-10-25');
      expect(oct25Sessions.length, 2);
      expect(events.totalStudySecondsForDate('2026-10-25'), 5400);

      // Verify non-matching date returns empty
      expect(events.goalsForDate('2026-10-01'), isEmpty);
      expect(events.blocksForDate('2026-10-01'), isEmpty);
      expect(events.sessionsForDate('2026-10-01'), isEmpty);
      expect(events.totalStudySecondsForDate('2026-10-01'), 0);
    });

    test('MonthYearKey equality works', () {
      const k1 = MonthYearKey(2026, 10);
      const k2 = MonthYearKey(2026, 10);
      const k3 = MonthYearKey(2026, 11);

      expect(k1, equals(k2));
      expect(k1.hashCode, equals(k2.hashCode));
      expect(k1 == k3, isFalse);
    });
  });

  group('Calendar Widget Tests', () {
    testWidgets('CalendarView renders monthly metrics and grid with mock events', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockEvents = CalendarMonthEvents(
        year: 2026,
        month: 10,
        goals: [
          CalendarGoalItem(
            id: 1,
            roadmapId: 10,
            roadmapTitle: 'Rust Systems Programming',
            targetDate: '2026-10-22',
          ),
        ],
        scheduleBlocks: [
          CalendarScheduleItem(
            id: 2,
            title: 'Memory Management Chapter',
            scheduledDate: '2026-10-22',
            startTime: '09:00',
            endTime: '10:30',
            isCompleted: false,
          ),
        ],
        studySessions: [
          CalendarStudyItem(
            id: 3,
            topicId: 20,
            topicTitle: 'Lifetimes & Borrowing',
            loggedDate: '2026-10-22',
            durationSeconds: 3600,
          ),
        ],
      );

      final testMonth = DateTime(2026, 10, 1);
      final testSelected = DateTime(2026, 10, 22);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            calendarMonthProvider.overrideWith((ref) => testMonth),
            selectedDateProvider.overrideWith((ref) => testSelected),
            calendarEventsProvider.overrideWith(
              () => _MockCalendarNotifier(mockEvents),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CalendarView(
                onAddBlockPressed: () {},
                onSwitchToDailyPressed: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check month header
      expect(find.text('October 2026'), findsOneWidget);

      // Check stats badges
      expect(find.text('1 Milestones'), findsOneWidget);
      expect(find.text('1 Study Blocks'), findsOneWidget);
      expect(find.text('1.0h Logged Study'), findsOneWidget);

      // Check weekday headers
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);

      // Check inspector details for selected date
      expect(find.text('Target Milestones'), findsOneWidget);
      expect(find.text('Rust Systems Programming'), findsWidgets);
      expect(find.text('Memory Management Chapter'), findsOneWidget);
      expect(find.text('Lifetimes & Borrowing'), findsOneWidget);
    });

    testWidgets('SchedulePage toggles between Daily Blocks and Calendar View', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            scheduleNotifierProvider.overrideWith(
              () => _MockScheduleNotifier(),
            ),
            calendarEventsProvider.overrideWith(
              () => _MockCalendarNotifier(
                CalendarMonthEvents(
                  year: DateTime.now().year,
                  month: DateTime.now().month,
                  goals: [],
                  scheduleBlocks: [],
                  studySessions: [],
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            home: SchedulePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially in Daily mode
      expect(find.text('Daily Study Schedule'), findsOneWidget);
      expect(find.text('Daily Blocks'), findsOneWidget);
      expect(find.text('Calendar View'), findsOneWidget);

      // Tap on Calendar View toggle
      await tester.tap(find.text('Calendar View'));
      await tester.pumpAndSettle();

      // Should now show Target Milestones & Calendar title
      expect(find.text('Target Milestones & Calendar'), findsOneWidget);
      expect(find.text('This Month'), findsNothing); // already current month
    });
  });
}

class _MockCalendarNotifier extends CalendarEventsNotifier {
  final CalendarMonthEvents mockEvents;
  _MockCalendarNotifier(this.mockEvents);

  @override
  Future<CalendarMonthEvents> build(MonthYearKey arg) async => mockEvents;
}

class _MockScheduleNotifier extends ScheduleNotifier {
  @override
  Future<List<ScheduleBlockModel>> build(String arg) async => [];
}
