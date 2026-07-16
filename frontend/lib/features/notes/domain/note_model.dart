class NoteModel {
  final int id;
  final int topicId;
  final String content;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.topicId,
    required this.content,
    required this.updatedAt,
  });

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'] as int,
        topicId: json['topic_id'] as int,
        content: json['content'] as String,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}
