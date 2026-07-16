// Domain models for Roadmap feature

class RoadmapModel {
  final int id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RoadmapModel({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoadmapModel.fromJson(Map<String, dynamic> json) => RoadmapModel(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class PhaseModel {
  final int id;
  final int roadmapId;
  final String title;
  final int orderIndex;

  const PhaseModel({
    required this.id,
    required this.roadmapId,
    required this.title,
    required this.orderIndex,
  });

  factory PhaseModel.fromJson(Map<String, dynamic> json) => PhaseModel(
        id: json['id'] as int,
        roadmapId: json['roadmap_id'] as int,
        title: json['title'] as String,
        orderIndex: json['order_index'] as int,
      );
}

class TopicModel {
  final int id;
  final int phaseId;
  final String title;
  final bool isCompleted;
  final int orderIndex;
  final DateTime? completedAt;

  const TopicModel({
    required this.id,
    required this.phaseId,
    required this.title,
    required this.isCompleted,
    required this.orderIndex,
    this.completedAt,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) => TopicModel(
        id: json['id'] as int,
        phaseId: json['phase_id'] as int,
        title: json['title'] as String,
        isCompleted: json['is_completed'] as bool,
        orderIndex: json['order_index'] as int,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );

  TopicModel copyWith({bool? isCompleted}) => TopicModel(
        id: id,
        phaseId: phaseId,
        title: title,
        isCompleted: isCompleted ?? this.isCompleted,
        orderIndex: orderIndex,
        completedAt: completedAt,
      );
}

class SubtopicModel {
  final int id;
  final int topicId;
  final String title;
  final bool isCompleted;
  final int orderIndex;

  const SubtopicModel({
    required this.id,
    required this.topicId,
    required this.title,
    required this.isCompleted,
    required this.orderIndex,
  });

  factory SubtopicModel.fromJson(Map<String, dynamic> json) => SubtopicModel(
        id: json['id'] as int,
        topicId: json['topic_id'] as int,
        title: json['title'] as String,
        isCompleted: json['is_completed'] as bool,
        orderIndex: json['order_index'] as int,
      );
}
