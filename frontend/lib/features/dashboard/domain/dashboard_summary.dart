// Dashboard domain models

class DashboardProgress {
  final int totalTopics;
  final int completedTopics;
  final int remainingTopics;
  final double progressPercent;

  const DashboardProgress({
    required this.totalTopics,
    required this.completedTopics,
    required this.remainingTopics,
    required this.progressPercent,
  });

  factory DashboardProgress.fromJson(Map<String, dynamic> json) => DashboardProgress(
        totalTopics: json['total_topics'] as int,
        completedTopics: json['completed_topics'] as int,
        remainingTopics: json['remaining_topics'] as int,
        progressPercent: (json['progress_percent'] as num).toDouble(),
      );
}

class PhaseProgress {
  final int phaseId;
  final String phaseTitle;
  final int totalTopics;
  final int completedTopics;
  final double progressPercent;

  const PhaseProgress({
    required this.phaseId,
    required this.phaseTitle,
    required this.totalTopics,
    required this.completedTopics,
    required this.progressPercent,
  });

  factory PhaseProgress.fromJson(Map<String, dynamic> json) => PhaseProgress(
        phaseId: json['phase_id'] as int,
        phaseTitle: json['phase_title'] as String,
        totalTopics: json['total_topics'] as int,
        completedTopics: json['completed_topics'] as int,
        progressPercent: (json['progress_percent'] as num).toDouble(),
      );
}

class GoalSummary {
  final String targetDate;
  final int daysRemaining;
  final double topicsPerDayNeeded;
  final bool isOverdue;

  const GoalSummary({
    required this.targetDate,
    required this.daysRemaining,
    required this.topicsPerDayNeeded,
    required this.isOverdue,
  });

  factory GoalSummary.fromJson(Map<String, dynamic> json) => GoalSummary(
        targetDate: json['target_date'] as String,
        daysRemaining: json['days_remaining'] as int,
        topicsPerDayNeeded: (json['topics_per_day_needed'] as num).toDouble(),
        isOverdue: json['is_overdue'] as bool,
      );
}

class TodaySuggestion {
  final int topicId;
  final String topicTitle;
  final String phaseTitle;

  const TodaySuggestion({
    required this.topicId,
    required this.topicTitle,
    required this.phaseTitle,
  });

  factory TodaySuggestion.fromJson(Map<String, dynamic> json) => TodaySuggestion(
        topicId: json['topic_id'] as int,
        topicTitle: json['topic_title'] as String,
        phaseTitle: json['phase_title'] as String,
      );
}

class DashboardSummary {
  final int roadmapId;
  final String roadmapTitle;
  final String? currentPhase;
  final String? currentTopic;
  final DashboardProgress progress;
  final List<PhaseProgress> phaseProgress;
  final GoalSummary? goal;
  final List<TodaySuggestion> todaySuggestions;

  const DashboardSummary({
    required this.roadmapId,
    required this.roadmapTitle,
    this.currentPhase,
    this.currentTopic,
    required this.progress,
    required this.phaseProgress,
    this.goal,
    required this.todaySuggestions,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        roadmapId: json['roadmap_id'] as int,
        roadmapTitle: json['roadmap_title'] as String,
        currentPhase: json['current_phase'] as String?,
        currentTopic: json['current_topic'] as String?,
        progress: DashboardProgress.fromJson(json['progress'] as Map<String, dynamic>),
        phaseProgress: (json['phase_progress'] as List<dynamic>)
            .map((e) => PhaseProgress.fromJson(e as Map<String, dynamic>))
            .toList(),
        goal: json['goal'] != null
            ? GoalSummary.fromJson(json['goal'] as Map<String, dynamic>)
            : null,
        todaySuggestions: (json['today_suggestions'] as List<dynamic>)
            .map((e) => TodaySuggestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
