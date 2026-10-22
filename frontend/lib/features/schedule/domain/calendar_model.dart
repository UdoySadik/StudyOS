class CalendarGoalItem {
  final int id;
  final int roadmapId;
  final String roadmapTitle;
  final String targetDate;

  CalendarGoalItem({
    required this.id,
    required this.roadmapId,
    required this.roadmapTitle,
    required this.targetDate,
  });

  factory CalendarGoalItem.fromJson(Map<String, dynamic> json) {
    return CalendarGoalItem(
      id: json['id'] as int,
      roadmapId: json['roadmap_id'] as int,
      roadmapTitle: json['roadmap_title'] as String? ?? 'Untitled Milestone',
      targetDate: json['target_date'] as String,
    );
  }
}

class CalendarScheduleItem {
  final int id;
  final String title;
  final String scheduledDate;
  final String startTime;
  final String endTime;
  final bool isCompleted;

  CalendarScheduleItem({
    required this.id,
    required this.title,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.isCompleted,
  });

  factory CalendarScheduleItem.fromJson(Map<String, dynamic> json) {
    return CalendarScheduleItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      scheduledDate: json['scheduled_date'] as String,
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }
}

class CalendarStudyItem {
  final int id;
  final int topicId;
  final String topicTitle;
  final String loggedDate;
  final int durationSeconds;

  CalendarStudyItem({
    required this.id,
    required this.topicId,
    required this.topicTitle,
    required this.loggedDate,
    required this.durationSeconds,
  });

  factory CalendarStudyItem.fromJson(Map<String, dynamic> json) {
    return CalendarStudyItem(
      id: json['id'] as int,
      topicId: json['topic_id'] as int,
      topicTitle: json['topic_title'] as String? ?? 'Topic',
      loggedDate: json['logged_date'] as String,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
    );
  }
}

class CalendarMonthEvents {
  final int year;
  final int month;
  final List<CalendarGoalItem> goals;
  final List<CalendarScheduleItem> scheduleBlocks;
  final List<CalendarStudyItem> studySessions;

  CalendarMonthEvents({
    required this.year,
    required this.month,
    required this.goals,
    required this.scheduleBlocks,
    required this.studySessions,
  });

  factory CalendarMonthEvents.fromJson(Map<String, dynamic> json) {
    return CalendarMonthEvents(
      year: json['year'] as int,
      month: json['month'] as int,
      goals: (json['goals'] as List<dynamic>? ?? [])
          .map((e) => CalendarGoalItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      scheduleBlocks: (json['schedule_blocks'] as List<dynamic>? ?? [])
          .map((e) => CalendarScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      studySessions: (json['study_sessions'] as List<dynamic>? ?? [])
          .map((e) => CalendarStudyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  List<CalendarGoalItem> goalsForDate(String dateStr) =>
      goals.where((g) => g.targetDate == dateStr).toList();

  List<CalendarScheduleItem> blocksForDate(String dateStr) =>
      scheduleBlocks.where((b) => b.scheduledDate == dateStr).toList();

  List<CalendarStudyItem> sessionsForDate(String dateStr) =>
      studySessions.where((s) => s.loggedDate == dateStr).toList();

  int totalStudySecondsForDate(String dateStr) =>
      sessionsForDate(dateStr).fold<int>(0, (sum, s) => sum + s.durationSeconds);
}
