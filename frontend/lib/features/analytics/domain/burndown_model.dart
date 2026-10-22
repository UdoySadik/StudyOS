class PhaseBurndownModel {
  final int phaseId;
  final String phaseTitle;
  final int orderIndex;
  final int totalTopics;
  final int completedTopics;
  final int remainingTopics;
  final double progressPercent;
  final double? estimatedDaysToComplete;

  PhaseBurndownModel({
    required this.phaseId,
    required this.phaseTitle,
    required this.orderIndex,
    required this.totalTopics,
    required this.completedTopics,
    required this.remainingTopics,
    required this.progressPercent,
    this.estimatedDaysToComplete,
  });

  factory PhaseBurndownModel.fromJson(Map<String, dynamic> json) {
    return PhaseBurndownModel(
      phaseId: json['phase_id'] as int,
      phaseTitle: json['phase_title'] as String? ?? 'Phase',
      orderIndex: json['order_index'] as int? ?? 0,
      totalTopics: json['total_topics'] as int? ?? 0,
      completedTopics: json['completed_topics'] as int? ?? 0,
      remainingTopics: json['remaining_topics'] as int? ?? 0,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      estimatedDaysToComplete: (json['estimated_days_to_complete'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase_id': phaseId,
      'phase_title': phaseTitle,
      'order_index': orderIndex,
      'total_topics': totalTopics,
      'completed_topics': completedTopics,
      'remaining_topics': remainingTopics,
      'progress_percent': progressPercent,
      'estimated_days_to_complete': estimatedDaysToComplete,
    };
  }
}

class DailyVelocityModel {
  final String date;
  final String dayLabel;
  final int topicsCompleted;
  final int studySeconds;

  DailyVelocityModel({
    required this.date,
    required this.dayLabel,
    required this.topicsCompleted,
    required this.studySeconds,
  });

  factory DailyVelocityModel.fromJson(Map<String, dynamic> json) {
    return DailyVelocityModel(
      date: json['date'] as String,
      dayLabel: json['day_label'] as String,
      topicsCompleted: json['topics_completed'] as int? ?? 0,
      studySeconds: json['study_seconds'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_label': dayLabel,
      'topics_completed': topicsCompleted,
      'study_seconds': studySeconds,
    };
  }
}

class RoadmapBurndownModel {
  final int roadmapId;
  final String roadmapTitle;
  final int totalTopics;
  final int completedTopics;
  final int remainingTopics;
  final double progressPercent;
  final String? targetDate;
  final int? daysRemaining;
  final double requiredVelocity;
  final double currentVelocity7d;
  final double currentStudyHours7d;
  final String status;
  final String statusLabel;
  final String? projectedCompletionDate;
  final List<PhaseBurndownModel> phases;
  final List<DailyVelocityModel> recentVelocity;

  RoadmapBurndownModel({
    required this.roadmapId,
    required this.roadmapTitle,
    required this.totalTopics,
    required this.completedTopics,
    required this.remainingTopics,
    required this.progressPercent,
    this.targetDate,
    this.daysRemaining,
    required this.requiredVelocity,
    required this.currentVelocity7d,
    required this.currentStudyHours7d,
    required this.status,
    required this.statusLabel,
    this.projectedCompletionDate,
    required this.phases,
    required this.recentVelocity,
  });

  factory RoadmapBurndownModel.fromJson(Map<String, dynamic> json) {
    return RoadmapBurndownModel(
      roadmapId: json['roadmap_id'] as int,
      roadmapTitle: json['roadmap_title'] as String? ?? 'Roadmap',
      totalTopics: json['total_topics'] as int? ?? 0,
      completedTopics: json['completed_topics'] as int? ?? 0,
      remainingTopics: json['remaining_topics'] as int? ?? 0,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['target_date'] as String?,
      daysRemaining: json['days_remaining'] as int?,
      requiredVelocity: (json['required_velocity'] as num?)?.toDouble() ?? 0.0,
      currentVelocity7d: (json['current_velocity_7d'] as num?)?.toDouble() ?? 0.0,
      currentStudyHours7d: (json['current_study_hours_7d'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'no_goal',
      statusLabel: json['status_label'] as String? ?? 'No Deadline Set',
      projectedCompletionDate: json['projected_completion_date'] as String?,
      phases: (json['phases'] as List<dynamic>? ?? [])
          .map((e) => PhaseBurndownModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentVelocity: (json['recent_velocity'] as List<dynamic>? ?? [])
          .map((e) => DailyVelocityModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roadmap_id': roadmapId,
      'roadmap_title': roadmapTitle,
      'total_topics': totalTopics,
      'completed_topics': completedTopics,
      'remaining_topics': remainingTopics,
      'progress_percent': progressPercent,
      'target_date': targetDate,
      'days_remaining': daysRemaining,
      'required_velocity': requiredVelocity,
      'current_velocity_7d': currentVelocity7d,
      'current_study_hours_7d': currentStudyHours7d,
      'status': status,
      'status_label': statusLabel,
      'projected_completion_date': projectedCompletionDate,
      'phases': phases.map((e) => e.toJson()).toList(),
      'recent_velocity': recentVelocity.map((e) => e.toJson()).toList(),
    };
  }
}
