// Goal domain model
class GoalModel {
  final int id;
  final int roadmapId;
  final String targetDate;
  final DateTime updatedAt;

  const GoalModel({
    required this.id,
    required this.roadmapId,
    required this.targetDate,
    required this.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
        id: json['id'] as int,
        roadmapId: json['roadmap_id'] as int,
        targetDate: json['target_date'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
