class DayConsistencyModel {
  final String date;
  final String dayLabel;
  final bool isActive;
  final int studySeconds;
  final int completedBlocks;
  final bool isToday;

  DayConsistencyModel({
    required this.date,
    required this.dayLabel,
    required this.isActive,
    required this.studySeconds,
    required this.completedBlocks,
    required this.isToday,
  });

  factory DayConsistencyModel.fromJson(Map<String, dynamic> json) {
    return DayConsistencyModel(
      date: json['date'] as String,
      dayLabel: json['day_label'] as String,
      isActive: json['is_active'] as bool? ?? false,
      studySeconds: json['study_seconds'] as int? ?? 0,
      completedBlocks: json['completed_blocks'] as int? ?? 0,
      isToday: json['is_today'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'day_label': dayLabel,
      'is_active': isActive,
      'study_seconds': studySeconds,
      'completed_blocks': completedBlocks,
      'is_today': isToday,
    };
  }
}

class StreakSummaryModel {
  final int currentStreak;
  final int longestStreak;
  final int totalActiveDays;
  final bool isActiveToday;
  final List<DayConsistencyModel> weeklyConsistency;
  final List<String> activeDatesLast30Days;

  StreakSummaryModel({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalActiveDays,
    required this.isActiveToday,
    required this.weeklyConsistency,
    required this.activeDatesLast30Days,
  });

  factory StreakSummaryModel.fromJson(Map<String, dynamic> json) {
    return StreakSummaryModel(
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      totalActiveDays: json['total_active_days'] as int? ?? 0,
      isActiveToday: json['is_active_today'] as bool? ?? false,
      weeklyConsistency: (json['weekly_consistency'] as List<dynamic>? ?? [])
          .map((e) => DayConsistencyModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeDatesLast30Days: (json['active_dates_last_30_days'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_active_days': totalActiveDays,
      'is_active_today': isActiveToday,
      'weekly_consistency': weeklyConsistency.map((e) => e.toJson()).toList(),
      'active_dates_last_30_days': activeDatesLast30Days,
    };
  }
}
