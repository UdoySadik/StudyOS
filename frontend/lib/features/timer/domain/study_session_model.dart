class StudySessionModel {
  final int id;
  final int topicId;
  final int durationSeconds;
  final String loggedDate;
  final String? notes;
  final String createdAt;

  StudySessionModel({
    required this.id,
    required this.topicId,
    required this.durationSeconds,
    required this.loggedDate,
    this.notes,
    required this.createdAt,
  });

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    return StudySessionModel(
      id: json['id'] as int,
      topicId: json['topic_id'] as int,
      durationSeconds: json['duration_seconds'] as int,
      loggedDate: json['logged_date'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class TopicStudyStatsModel {
  final int topicId;
  final String? topicTitle;
  final int totalSeconds;
  final int sessionCount;

  TopicStudyStatsModel({
    required this.topicId,
    this.topicTitle,
    required this.totalSeconds,
    required this.sessionCount,
  });

  factory TopicStudyStatsModel.fromJson(Map<String, dynamic> json) {
    return TopicStudyStatsModel(
      topicId: json['topic_id'] as int,
      topicTitle: json['topic_title'] as String?,
      totalSeconds: json['total_seconds'] as int? ?? 0,
      sessionCount: json['session_count'] as int? ?? 0,
    );
  }

  String get formattedDuration {
    if (totalSeconds < 60) {
      return '${totalSeconds}s';
    }
    final minutes = totalSeconds ~/ 60;
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remainingMinutes}m';
  }
}

class StudySummaryModel {
  final int totalSecondsToday;
  final int totalSecondsAllTime;
  final int totalSessionsCount;
  final List<TopicStudyStatsModel> topicStats;

  StudySummaryModel({
    required this.totalSecondsToday,
    required this.totalSecondsAllTime,
    required this.totalSessionsCount,
    required this.topicStats,
  });

  factory StudySummaryModel.fromJson(Map<String, dynamic> json) {
    final list = json['topic_stats'] as List<dynamic>? ?? [];
    return StudySummaryModel(
      totalSecondsToday: json['total_seconds_today'] as int? ?? 0,
      totalSecondsAllTime: json['total_seconds_all_time'] as int? ?? 0,
      totalSessionsCount: json['total_sessions_count'] as int? ?? 0,
      topicStats: list.map((e) => TopicStudyStatsModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  String get formattedToday {
    final minutes = totalSecondsToday ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '${hours}h' : '${hours}h ${rem}m';
  }

  String get formattedAllTime {
    final minutes = totalSecondsAllTime ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '${hours}h' : '${hours}h ${rem}m';
  }
}
