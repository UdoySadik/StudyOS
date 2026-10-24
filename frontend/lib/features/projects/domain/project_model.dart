import 'package:flutter/material.dart';

class ProjectModel {
  final int id;
  final int roadmapId;
  final int? topicId;
  final String title;
  final String? description;
  final String? githubUrl;
  final String? liveUrl;
  final String status; // 'not_started', 'in_progress', 'completed', 'on_hold'
  final String difficulty; // 'beginner', 'medium', 'advanced'
  final String? techStack;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? roadmapTitle;
  final String? topicTitle;

  const ProjectModel({
    required this.id,
    required this.roadmapId,
    this.topicId,
    required this.title,
    this.description,
    this.githubUrl,
    this.liveUrl,
    this.status = 'not_started',
    this.difficulty = 'medium',
    this.techStack,
    this.createdAt,
    this.completedAt,
    this.roadmapTitle,
    this.topicTitle,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as int,
      roadmapId: json['roadmap_id'] as int,
      topicId: json['topic_id'] as int?,
      title: json['title'] as String? ?? 'Untitled Project',
      description: json['description'] as String?,
      githubUrl: json['github_url'] as String?,
      liveUrl: json['live_url'] as String?,
      status: json['status'] as String? ?? 'not_started',
      difficulty: json['difficulty'] as String? ?? 'medium',
      techStack: json['tech_stack'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'] as String) : null,
      roadmapTitle: json['roadmap_title'] as String?,
      topicTitle: json['topic_title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roadmap_id': roadmapId,
      'topic_id': topicId,
      'title': title,
      'description': description,
      'github_url': githubUrl,
      'live_url': liveUrl,
      'status': status,
      'difficulty': difficulty,
      'tech_stack': techStack,
      'created_at': createdAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'roadmap_title': roadmapTitle,
      'topic_title': topicTitle,
    };
  }

  ProjectModel copyWith({
    int? id,
    int? roadmapId,
    int? topicId,
    String? title,
    String? description,
    String? githubUrl,
    String? liveUrl,
    String? status,
    String? difficulty,
    String? techStack,
    DateTime? createdAt,
    DateTime? completedAt,
    String? roadmapTitle,
    String? topicTitle,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      roadmapId: roadmapId ?? this.roadmapId,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      description: description ?? this.description,
      githubUrl: githubUrl ?? this.githubUrl,
      liveUrl: liveUrl ?? this.liveUrl,
      status: status ?? this.status,
      difficulty: difficulty ?? this.difficulty,
      techStack: techStack ?? this.techStack,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      roadmapTitle: roadmapTitle ?? this.roadmapTitle,
      topicTitle: topicTitle ?? this.topicTitle,
    );
  }

  List<String> get techStackList {
    if (techStack == null || techStack!.trim().isEmpty) return [];
    return techStack!
        .split(RegExp(r'[,|;]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  bool get isCompleted => status == 'completed';

  Color get statusColor {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'on_hold':
        return const Color(0xFFF59E0B);
      case 'not_started':
      default:
        return const Color(0xFF9494B0);
    }
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'on_hold':
        return 'On Hold';
      case 'not_started':
      default:
        return 'Not Started';
    }
  }

  Color get difficultyColor {
    switch (difficulty) {
      case 'beginner':
        return const Color(0xFF10B981);
      case 'advanced':
        return const Color(0xFFEF4444);
      case 'medium':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'beginner':
        return 'Beginner';
      case 'advanced':
        return 'Advanced';
      case 'medium':
      default:
        return 'Medium';
    }
  }
}
