import 'package:flutter/material.dart';

class OllamaStatusModel {
  final bool connected;
  final String endpoint;
  final List<String> models;

  const OllamaStatusModel({
    required this.connected,
    required this.endpoint,
    required this.models,
  });

  factory OllamaStatusModel.fromJson(Map<String, dynamic> json) {
    final rawModels = json['models'] as List<dynamic>? ?? [];
    return OllamaStatusModel(
      connected: json['connected'] as bool? ?? false,
      endpoint: json['endpoint'] as String? ?? 'http://127.0.0.1:11434',
      models: rawModels.map((e) => e.toString()).toList(),
    );
  }
}

class StudyPlanModel {
  final int id;
  final String title;
  final String subject;
  final String proficiency;
  final int hoursPerWeek;
  final int targetWeeks;
  final String modelUsed;
  final String planMarkdown;
  final Map<String, dynamic>? structuredData;
  final int? roadmapId;
  final String? roadmapTitle;
  final DateTime? createdAt;

  const StudyPlanModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.proficiency,
    required this.hoursPerWeek,
    required this.targetWeeks,
    required this.modelUsed,
    required this.planMarkdown,
    this.structuredData,
    this.roadmapId,
    this.roadmapTitle,
    this.createdAt,
  });

  factory StudyPlanModel.fromJson(Map<String, dynamic> json) {
    return StudyPlanModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Study Plan',
      subject: json['subject'] as String? ?? '',
      proficiency: json['proficiency'] as String? ?? 'intermediate',
      hoursPerWeek: json['hours_per_week'] as int? ?? 10,
      targetWeeks: json['target_weeks'] as int? ?? 4,
      modelUsed: json['model_used'] as String? ?? 'builtin-offline',
      planMarkdown: json['plan_markdown'] as String? ?? '',
      structuredData: json['structured_data'] as Map<String, dynamic>?,
      roadmapId: json['roadmap_id'] as int?,
      roadmapTitle: json['roadmap_title'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'proficiency': proficiency,
      'hours_per_week': hoursPerWeek,
      'target_weeks': targetWeeks,
      'model_used': modelUsed,
      'plan_markdown': planMarkdown,
      'structured_data': structuredData,
      'roadmap_id': roadmapId,
      'roadmap_title': roadmapTitle,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  StudyPlanModel copyWith({
    int? id,
    String? title,
    String? subject,
    String? proficiency,
    int? hoursPerWeek,
    int? targetWeeks,
    String? modelUsed,
    String? planMarkdown,
    Map<String, dynamic>? structuredData,
    int? roadmapId,
    String? roadmapTitle,
    DateTime? createdAt,
  }) {
    return StudyPlanModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      proficiency: proficiency ?? this.proficiency,
      hoursPerWeek: hoursPerWeek ?? this.hoursPerWeek,
      targetWeeks: targetWeeks ?? this.targetWeeks,
      modelUsed: modelUsed ?? this.modelUsed,
      planMarkdown: planMarkdown ?? this.planMarkdown,
      structuredData: structuredData ?? this.structuredData,
      roadmapId: roadmapId ?? this.roadmapId,
      roadmapTitle: roadmapTitle ?? this.roadmapTitle,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get totalHours => hoursPerWeek * targetWeeks;
  bool get isImported => roadmapId != null;

  Color get proficiencyColor {
    switch (proficiency.toLowerCase()) {
      case 'beginner':
        return const Color(0xFF10B981);
      case 'advanced':
        return const Color(0xFFEF4444);
      case 'intermediate':
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
