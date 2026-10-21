class ScheduleBlockModel {
  final int id;
  final String scheduledDate;
  final String startTime;
  final String endTime;
  final String title;
  final int? topicId;
  final bool isCompleted;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  ScheduleBlockModel({
    required this.id,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.topicId,
    required this.isCompleted,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScheduleBlockModel.fromJson(Map<String, dynamic> json) {
    return ScheduleBlockModel(
      id: json['id'] as int,
      scheduledDate: json['scheduled_date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      title: json['title'] as String,
      topicId: json['topic_id'] as int?,
      isCompleted: json['is_completed'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scheduled_date': scheduledDate,
      'start_time': startTime,
      'end_time': endTime,
      'title': title,
      'topic_id': topicId,
      'is_completed': isCompleted,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
