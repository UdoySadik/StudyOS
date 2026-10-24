import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/project_model.dart';

final projectStatusFilterProvider = StateProvider<String?>((ref) => null);
final projectRoadmapFilterProvider = StateProvider<int?>((ref) => null);
final projectSearchQueryProvider = StateProvider<String>((ref) => '');

class ProjectStats {
  final int total;
  final int completed;
  final int inProgress;
  final int notStarted;
  final int onHold;
  final double completionRate;

  const ProjectStats({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.notStarted,
    required this.onHold,
    required this.completionRate,
  });
}

final projectsListProvider =
    AsyncNotifierProvider<ProjectsListNotifier, List<ProjectModel>>(
  ProjectsListNotifier.new,
);

class ProjectsListNotifier extends AsyncNotifier<List<ProjectModel>> {
  @override
  Future<List<ProjectModel>> build() async {
    final res = await ApiService().get('/projects/') as List<dynamic>;
    return res.map((e) => ProjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createProject({
    required int roadmapId,
    int? topicId,
    required String title,
    String? description,
    String? githubUrl,
    String? liveUrl,
    String status = 'not_started',
    String difficulty = 'medium',
    String? techStack,
  }) async {
    final payload = {
      'roadmap_id': roadmapId,
      if (topicId != null && topicId > 0) 'topic_id': topicId,
      'title': title.trim(),
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'github_url': githubUrl?.trim().isEmpty == true ? null : githubUrl?.trim(),
      'live_url': liveUrl?.trim().isEmpty == true ? null : liveUrl?.trim(),
      'status': status,
      'difficulty': difficulty,
      'tech_stack': techStack?.trim().isEmpty == true ? null : techStack?.trim(),
    };
    await ApiService().post('/projects/', payload);
    ref.invalidateSelf();
  }

  Future<void> updateProject(
    int id, {
    int? roadmapId,
    int? topicId,
    String? title,
    String? description,
    String? githubUrl,
    String? liveUrl,
    String? status,
    String? difficulty,
    String? techStack,
  }) async {
    final payload = <String, dynamic>{};
    if (roadmapId != null) payload['roadmap_id'] = roadmapId;
    if (topicId != null) payload['topic_id'] = topicId > 0 ? topicId : null;
    if (title != null) payload['title'] = title.trim();
    if (description != null) payload['description'] = description.trim().isEmpty ? null : description.trim();
    if (githubUrl != null) payload['github_url'] = githubUrl.trim().isEmpty ? null : githubUrl.trim();
    if (liveUrl != null) payload['live_url'] = liveUrl.trim().isEmpty ? null : liveUrl.trim();
    if (status != null) payload['status'] = status;
    if (difficulty != null) payload['difficulty'] = difficulty;
    if (techStack != null) payload['tech_stack'] = techStack.trim().isEmpty ? null : techStack.trim();

    await ApiService().patch('/projects/$id', payload);
    ref.invalidateSelf();
  }

  Future<void> updateStatus(int id, String status) async {
    await ApiService().patch('/projects/$id/status', {'status': status});
    ref.invalidateSelf();
  }

  Future<void> deleteProject(int id) async {
    await ApiService().delete('/projects/$id');
    ref.invalidateSelf();
  }
}

final filteredProjectsProvider = Provider<AsyncValue<List<ProjectModel>>>((ref) {
  final projectsAsync = ref.watch(projectsListProvider);
  final statusFilter = ref.watch(projectStatusFilterProvider);
  final roadmapFilter = ref.watch(projectRoadmapFilterProvider);
  final searchQuery = ref.watch(projectSearchQueryProvider).trim().toLowerCase();

  return projectsAsync.whenData((projects) {
    return projects.where((p) {
      if (statusFilter != null && p.status != statusFilter) {
        return false;
      }
      if (roadmapFilter != null && p.roadmapId != roadmapFilter) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final titleMatch = p.title.toLowerCase().contains(searchQuery);
        final descMatch = p.description?.toLowerCase().contains(searchQuery) ?? false;
        final techMatch = p.techStack?.toLowerCase().contains(searchQuery) ?? false;
        final roadmapMatch = p.roadmapTitle?.toLowerCase().contains(searchQuery) ?? false;
        final topicMatch = p.topicTitle?.toLowerCase().contains(searchQuery) ?? false;
        if (!titleMatch && !descMatch && !techMatch && !roadmapMatch && !topicMatch) {
          return false;
        }
      }
      return true;
    }).toList();
  });
});

final projectStatsProvider = Provider<ProjectStats>((ref) {
  final projectsAsync = ref.watch(projectsListProvider);
  final projects = projectsAsync.valueOrNull ?? [];
  final total = projects.length;
  final completed = projects.where((p) => p.status == 'completed').length;
  final inProgress = projects.where((p) => p.status == 'in_progress').length;
  final notStarted = projects.where((p) => p.status == 'not_started').length;
  final onHold = projects.where((p) => p.status == 'on_hold').length;
  final rate = total > 0 ? (completed / total) : 0.0;

  return ProjectStats(
    total: total,
    completed: completed,
    inProgress: inProgress,
    notStarted: notStarted,
    onHold: onHold,
    completionRate: rate,
  );
});
