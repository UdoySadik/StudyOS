class ResourceModel {
  final int id;
  final int topicId;
  final String title;
  final String resourceType; // "book", "video", "article", "course", "pdf", "doc", "github"
  final String? url;
  final String? notes;
  final bool isCompleted;
  final DateTime? createdAt;

  ResourceModel({
    required this.id,
    required this.topicId,
    required this.title,
    required this.resourceType,
    this.url,
    this.notes,
    required this.isCompleted,
    this.createdAt,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as int,
      topicId: json['topic_id'] as int,
      title: json['title'] as String? ?? 'Untitled Resource',
      resourceType: json['resource_type'] as String? ?? 'article',
      url: json['url'] as String?,
      notes: json['notes'] as String?,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'title': title,
      'resource_type': resourceType,
      'url': url,
      'notes': notes,
      'is_completed': isCompleted,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  ResourceModel copyWith({
    int? id,
    int? topicId,
    String? title,
    String? resourceType,
    String? url,
    String? notes,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ResourceModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      resourceType: resourceType ?? this.resourceType,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
