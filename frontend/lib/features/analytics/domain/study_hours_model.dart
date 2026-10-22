class DayStudyHourModel {
  final String date;
  final int dayOfMonth;
  final String dayLabel;
  final int studySeconds;
  final double studyHours;
  final int sessionCount;

  DayStudyHourModel({
    required this.date,
    required this.dayOfMonth,
    required this.dayLabel,
    required this.studySeconds,
    required this.studyHours,
    required this.sessionCount,
  });

  factory DayStudyHourModel.fromJson(Map<String, dynamic> json) {
    return DayStudyHourModel(
      date: json['date'] as String,
      dayOfMonth: json['day_of_month'] as int? ?? 1,
      dayLabel: json['day_label'] as String? ?? '',
      studySeconds: json['study_seconds'] as int? ?? 0,
      studyHours: (json['study_hours'] as num?)?.toDouble() ?? 0.0,
      sessionCount: json['session_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_of_month': dayOfMonth,
      'day_label': dayLabel,
      'study_seconds': studySeconds,
      'study_hours': studyHours,
      'session_count': sessionCount,
    };
  }
}

class TopicStudyHourModel {
  final int topicId;
  final String topicTitle;
  final String phaseTitle;
  final int studySeconds;
  final double studyHours;
  final double percentage;

  TopicStudyHourModel({
    required this.topicId,
    required this.topicTitle,
    required this.phaseTitle,
    required this.studySeconds,
    required this.studyHours,
    required this.percentage,
  });

  factory TopicStudyHourModel.fromJson(Map<String, dynamic> json) {
    return TopicStudyHourModel(
      topicId: json['topic_id'] as int,
      topicTitle: json['topic_title'] as String? ?? 'Untitled Topic',
      phaseTitle: json['phase_title'] as String? ?? 'General',
      studySeconds: json['study_seconds'] as int? ?? 0,
      studyHours: (json['study_hours'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topic_id': topicId,
      'topic_title': topicTitle,
      'phase_title': phaseTitle,
      'study_seconds': studySeconds,
      'study_hours': studyHours,
      'percentage': percentage,
    };
  }
}

class WeekdayStudyHourModel {
  final int weekdayIndex;
  final String dayName;
  final int totalSeconds;
  final double totalHours;
  final int sessionCount;

  WeekdayStudyHourModel({
    required this.weekdayIndex,
    required this.dayName,
    required this.totalSeconds,
    required this.totalHours,
    required this.sessionCount,
  });

  factory WeekdayStudyHourModel.fromJson(Map<String, dynamic> json) {
    return WeekdayStudyHourModel(
      weekdayIndex: json['weekday_index'] as int? ?? 0,
      dayName: json['day_name'] as String? ?? '',
      totalSeconds: json['total_seconds'] as int? ?? 0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      sessionCount: json['session_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekday_index': weekdayIndex,
      'day_name': dayName,
      'total_seconds': totalSeconds,
      'total_hours': totalHours,
      'session_count': sessionCount,
    };
  }
}

class MonthlyStudyHoursModel {
  final int year;
  final int month;
  final String monthName;
  final int? roadmapId;
  final int totalSeconds;
  final double totalHours;
  final int totalSessions;
  final int activeDaysCount;
  final int totalDaysInMonth;
  final double dailyAverageHours;
  final String? peakDayDate;
  final double peakDayHours;
  final List<DayStudyHourModel> dailyDistribution;
  final List<TopicStudyHourModel> topicDistribution;
  final List<WeekdayStudyHourModel> weekdayDistribution;

  MonthlyStudyHoursModel({
    required this.year,
    required this.month,
    required this.monthName,
    this.roadmapId,
    required this.totalSeconds,
    required this.totalHours,
    required this.totalSessions,
    required this.activeDaysCount,
    required this.totalDaysInMonth,
    required this.dailyAverageHours,
    this.peakDayDate,
    required this.peakDayHours,
    required this.dailyDistribution,
    required this.topicDistribution,
    required this.weekdayDistribution,
  });

  factory MonthlyStudyHoursModel.fromJson(Map<String, dynamic> json) {
    return MonthlyStudyHoursModel(
      year: json['year'] as int,
      month: json['month'] as int,
      monthName: json['month_name'] as String? ?? '',
      roadmapId: json['roadmap_id'] as int?,
      totalSeconds: json['total_seconds'] as int? ?? 0,
      totalHours: (json['total_hours'] as num?)?.toDouble() ?? 0.0,
      totalSessions: json['total_sessions'] as int? ?? 0,
      activeDaysCount: json['active_days_count'] as int? ?? 0,
      totalDaysInMonth: json['total_days_in_month'] as int? ?? 30,
      dailyAverageHours: (json['daily_average_hours'] as num?)?.toDouble() ?? 0.0,
      peakDayDate: json['peak_day_date'] as String?,
      peakDayHours: (json['peak_day_hours'] as num?)?.toDouble() ?? 0.0,
      dailyDistribution: (json['daily_distribution'] as List<dynamic>? ?? [])
          .map((e) => DayStudyHourModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      topicDistribution: (json['topic_distribution'] as List<dynamic>? ?? [])
          .map((e) => TopicStudyHourModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      weekdayDistribution: (json['weekday_distribution'] as List<dynamic>? ?? [])
          .map((e) => WeekdayStudyHourModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'month_name': monthName,
      'roadmap_id': roadmapId,
      'total_seconds': totalSeconds,
      'total_hours': totalHours,
      'total_sessions': totalSessions,
      'active_days_count': activeDaysCount,
      'total_days_in_month': totalDaysInMonth,
      'daily_average_hours': dailyAverageHours,
      'peak_day_date': peakDayDate,
      'peak_day_hours': peakDayHours,
      'daily_distribution': dailyDistribution.map((e) => e.toJson()).toList(),
      'topic_distribution': topicDistribution.map((e) => e.toJson()).toList(),
      'weekday_distribution': weekdayDistribution.map((e) => e.toJson()).toList(),
    };
  }
}
