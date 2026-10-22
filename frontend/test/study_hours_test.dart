import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyos/features/analytics/application/study_hours_provider.dart';
import 'package:studyos/features/analytics/domain/study_hours_model.dart';
import 'package:studyos/features/analytics/presentation/study_hours_distribution_card.dart';

void main() {
  group('StudyHoursModel Domain Tests', () {
    test('DayStudyHourModel serializes & deserializes correctly', () {
      final json = {
        'date': '2026-10-15',
        'day_of_month': 15,
        'day_label': 'Thu',
        'study_seconds': 7200,
        'study_hours': 2.0,
        'session_count': 2,
      };

      final model = DayStudyHourModel.fromJson(json);
      expect(model.date, '2026-10-15');
      expect(model.dayOfMonth, 15);
      expect(model.dayLabel, 'Thu');
      expect(model.studySeconds, 7200);
      expect(model.studyHours, 2.0);
      expect(model.sessionCount, 2);

      final exported = model.toJson();
      expect(exported['date'], '2026-10-15');
      expect(exported['study_seconds'], 7200);
    });

    test('TopicStudyHourModel and WeekdayStudyHourModel parse correctly', () {
      final topicJson = {
        'topic_id': 10,
        'topic_title': 'Raft Consensus Algorithm',
        'phase_title': 'Distributed Core',
        'study_seconds': 14400,
        'study_hours': 4.0,
        'percentage': 40.0,
      };
      final topic = TopicStudyHourModel.fromJson(topicJson);
      expect(topic.topicId, 10);
      expect(topic.topicTitle, 'Raft Consensus Algorithm');
      expect(topic.phaseTitle, 'Distributed Core');
      expect(topic.studyHours, 4.0);
      expect(topic.percentage, 40.0);

      final weekdayJson = {
        'weekday_index': 1,
        'day_name': 'Tuesday',
        'total_seconds': 10800,
        'total_hours': 3.0,
        'session_count': 3,
      };
      final weekday = WeekdayStudyHourModel.fromJson(weekdayJson);
      expect(weekday.weekdayIndex, 1);
      expect(weekday.dayName, 'Tuesday');
      expect(weekday.totalHours, 3.0);
      expect(weekday.sessionCount, 3);
    });

    test('MonthlyStudyHoursModel parses complete response correctly', () {
      final json = {
        'year': 2026,
        'month': 10,
        'month_name': 'October 2026',
        'roadmap_id': 1,
        'total_seconds': 36000,
        'total_hours': 10.0,
        'total_sessions': 8,
        'active_days_count': 5,
        'total_days_in_month': 31,
        'daily_average_hours': 2.0,
        'peak_day_date': '2026-10-12',
        'peak_day_hours': 3.5,
        'daily_distribution': [
          {
            'date': '2026-10-01',
            'day_of_month': 1,
            'day_label': 'Thu',
            'study_seconds': 3600,
            'study_hours': 1.0,
            'session_count': 1,
          },
          {
            'date': '2026-10-02',
            'day_of_month': 2,
            'day_label': 'Fri',
            'study_seconds': 0,
            'study_hours': 0.0,
            'session_count': 0,
          },
        ],
        'topic_distribution': [
          {
            'topic_id': 1,
            'topic_title': 'Algorithms',
            'phase_title': 'CS Core',
            'study_seconds': 36000,
            'study_hours': 10.0,
            'percentage': 100.0,
          },
        ],
        'weekday_distribution': [
          {
            'weekday_index': 0,
            'day_name': 'Monday',
            'total_seconds': 7200,
            'total_hours': 2.0,
            'session_count': 2,
          },
        ],
      };

      final model = MonthlyStudyHoursModel.fromJson(json);
      expect(model.year, 2026);
      expect(model.month, 10);
      expect(model.monthName, 'October 2026');
      expect(model.totalHours, 10.0);
      expect(model.activeDaysCount, 5);
      expect(model.dailyAverageHours, 2.0);
      expect(model.peakDayDate, '2026-10-12');
      expect(model.peakDayHours, 3.5);
      expect(model.dailyDistribution.length, 2);
      expect(model.topicDistribution.length, 1);
      expect(model.weekdayDistribution.length, 1);
    });
  });

  group('StudyHoursDistributionCard Presentation Widget Tests', () {
    testWidgets('StudyHoursDistributionCard renders metrics, histogram, topics, and weekdays', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockModel = MonthlyStudyHoursModel(
        year: 2026,
        month: 10,
        monthName: 'October 2026',
        roadmapId: 1,
        totalSeconds: 36000,
        totalHours: 10.0,
        totalSessions: 6,
        activeDaysCount: 4,
        totalDaysInMonth: 31,
        dailyAverageHours: 2.5,
        peakDayDate: '2026-10-15',
        peakDayHours: 4.0,
        dailyDistribution: List.generate(31, (index) {
          final day = index + 1;
          final isStudied = day == 5 || day == 10 || day == 15 || day == 20;
          return DayStudyHourModel(
            date: '2026-10-${day.toString().padLeft(2, '0')}',
            dayOfMonth: day,
            dayLabel: 'Day',
            studySeconds: isStudied ? 7200 : 0,
            studyHours: isStudied ? 2.0 : 0.0,
            sessionCount: isStudied ? 1 : 0,
          );
        }),
        topicDistribution: [
          TopicStudyHourModel(
            topicId: 1,
            topicTitle: 'Memory Management',
            phaseTitle: 'Rust Internals',
            studySeconds: 21600,
            studyHours: 6.0,
            percentage: 60.0,
          ),
          TopicStudyHourModel(
            topicId: 2,
            topicTitle: 'Concurrency Primitives',
            phaseTitle: 'Rust Internals',
            studySeconds: 14400,
            studyHours: 4.0,
            percentage: 40.0,
          ),
        ],
        weekdayDistribution: [
          WeekdayStudyHourModel(weekdayIndex: 0, dayName: 'Monday', totalSeconds: 7200, totalHours: 2.0, sessionCount: 1),
          WeekdayStudyHourModel(weekdayIndex: 1, dayName: 'Tuesday', totalSeconds: 14400, totalHours: 4.0, sessionCount: 2),
          WeekdayStudyHourModel(weekdayIndex: 2, dayName: 'Wednesday', totalSeconds: 0, totalHours: 0.0, sessionCount: 0),
          WeekdayStudyHourModel(weekdayIndex: 3, dayName: 'Thursday', totalSeconds: 7200, totalHours: 2.0, sessionCount: 1),
          WeekdayStudyHourModel(weekdayIndex: 4, dayName: 'Friday', totalSeconds: 7200, totalHours: 2.0, sessionCount: 1),
          WeekdayStudyHourModel(weekdayIndex: 5, dayName: 'Saturday', totalSeconds: 0, totalHours: 0.0, sessionCount: 0),
          WeekdayStudyHourModel(weekdayIndex: 6, dayName: 'Sunday', totalSeconds: 0, totalHours: 0.0, sessionCount: 0),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studyHoursMonthProvider.overrideWith((ref) => DateTime(2026, 10)),
            studyHoursProvider.overrideWith(() => _MockStudyHoursNotifier(mockModel)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StudyHoursDistributionCard(roadmapId: 1),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Monthly Study Hours Distribution'), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget); // Month navigator
      expect(find.text('Daily Study Volume (October 2026)'), findsOneWidget);

      // Check metric tiles
      expect(find.text('Total Studied'), findsOneWidget);
      expect(find.text('10.0h'), findsOneWidget);
      expect(find.text('6 sessions logged'), findsOneWidget);

      expect(find.text('Active Days'), findsOneWidget);
      expect(find.text('4 / 31'), findsOneWidget);

      expect(find.text('Daily Average'), findsOneWidget);
      expect(find.text('2.5h'), findsOneWidget);

      expect(find.text('Peak Day'), findsOneWidget);
      expect(find.text('4.0h'), findsNWidgets(2)); // Peak Day metric and Tuesday weekday habit

      // Check Topics breakdown
      expect(find.text('Top Topics Studied'), findsOneWidget);
      expect(find.text('Memory Management'), findsOneWidget);
      expect(find.text('6.0h (60.0%)'), findsOneWidget);
      expect(find.text('Concurrency Primitives'), findsOneWidget);
      expect(find.text('4.0h (40.0%)'), findsOneWidget);

      // Check Weekday breakdown
      expect(find.text('Weekly Habit Pattern'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
    });

    testWidgets('StudyHoursDistributionCard renders clean empty state when no hours', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final emptyModel = MonthlyStudyHoursModel(
        year: 2026,
        month: 11,
        monthName: 'November 2026',
        roadmapId: 1,
        totalSeconds: 0,
        totalHours: 0.0,
        totalSessions: 0,
        activeDaysCount: 0,
        totalDaysInMonth: 30,
        dailyAverageHours: 0.0,
        peakDayDate: null,
        peakDayHours: 0.0,
        dailyDistribution: [],
        topicDistribution: [],
        weekdayDistribution: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studyHoursMonthProvider.overrideWith((ref) => DateTime(2026, 11)),
            studyHoursProvider.overrideWith(() => _MockStudyHoursNotifier(emptyModel)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StudyHoursDistributionCard(roadmapId: 1),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Monthly Study Hours Distribution'), findsOneWidget);
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text('No study sessions logged in November 2026.'), findsOneWidget);
      expect(find.text('No topics studied this month'), findsOneWidget);
    });
  });
}

class _MockStudyHoursNotifier extends StudyHoursNotifier {
  final MonthlyStudyHoursModel mockData;
  _MockStudyHoursNotifier(this.mockData);

  @override
  Future<MonthlyStudyHoursModel> build(StudyHoursFilter arg) async => mockData;
}
