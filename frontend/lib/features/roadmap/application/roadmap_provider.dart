import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/roadmap_models.dart';

// ── Providers ────────────────────────────────────────────────────────────────

final roadmapsProvider = FutureProvider<List<RoadmapModel>>((ref) async {
  final data = await ApiService().get('/roadmaps/') as List<dynamic>;
  return data.map((e) => RoadmapModel.fromJson(e as Map<String, dynamic>)).toList();
});

final selectedRoadmapIdProvider = StateProvider<int?>((ref) => null);

final phasesProvider = FutureProvider.family<List<PhaseModel>, int>((ref, roadmapId) async {
  final data = await ApiService().get('/phases/roadmap/$roadmapId') as List<dynamic>;
  return data.map((e) => PhaseModel.fromJson(e as Map<String, dynamic>)).toList();
});

final topicsProvider = FutureProvider.family<List<TopicModel>, int>((ref, phaseId) async {
  final data = await ApiService().get('/topics/phase/$phaseId') as List<dynamic>;
  return data.map((e) => TopicModel.fromJson(e as Map<String, dynamic>)).toList();
});

final subtopicsProvider = FutureProvider.family<List<SubtopicModel>, int>((ref, topicId) async {
  final data = await ApiService().get('/subtopics/topic/$topicId') as List<dynamic>;
  return data.map((e) => SubtopicModel.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Notifiers ─────────────────────────────────────────────────────────────────

class RoadmapNotifier extends AsyncNotifier<List<RoadmapModel>> {
  @override
  Future<List<RoadmapModel>> build() async {
    final data = await ApiService().get('/roadmaps/') as List<dynamic>;
    return data.map((e) => RoadmapModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createRoadmap(String title, {String? description}) async {
    await ApiService().post('/roadmaps/', {'title': title, 'description': description});
    ref.invalidateSelf();
  }

  Future<void> deleteRoadmap(int id) async {
    await ApiService().delete('/roadmaps/$id');
    ref.invalidateSelf();
  }

  Future<void> updateRoadmap(int id, String title, {String? description}) async {
    await ApiService().patch('/roadmaps/$id', {'title': title, 'description': description});
    ref.invalidateSelf();
  }
}

final roadmapNotifierProvider =
    AsyncNotifierProvider<RoadmapNotifier, List<RoadmapModel>>(RoadmapNotifier.new);

class PhaseNotifier extends FamilyAsyncNotifier<List<PhaseModel>, int> {
  @override
  Future<List<PhaseModel>> build(int roadmapId) async {
    final data = await ApiService().get('/phases/roadmap/$roadmapId') as List<dynamic>;
    return data.map((e) => PhaseModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addPhase(String title) async {
    await ApiService().post('/phases/', {'roadmap_id': arg, 'title': title});
    ref.invalidateSelf();
  }

  Future<void> deletePhase(int phaseId) async {
    await ApiService().delete('/phases/$phaseId');
    ref.invalidateSelf();
  }

  Future<void> updatePhase(int phaseId, String title) async {
    await ApiService().patch('/phases/$phaseId', {'title': title});
    ref.invalidateSelf();
  }
}

final phaseNotifierProvider =
    AsyncNotifierProviderFamily<PhaseNotifier, List<PhaseModel>, int>(PhaseNotifier.new);

class TopicNotifier extends FamilyAsyncNotifier<List<TopicModel>, int> {
  @override
  Future<List<TopicModel>> build(int phaseId) async {
    final data = await ApiService().get('/topics/phase/$phaseId') as List<dynamic>;
    return data.map((e) => TopicModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addTopic(String title) async {
    await ApiService().post('/topics/', {'phase_id': arg, 'title': title});
    ref.invalidateSelf();
  }

  Future<void> deleteTopic(int topicId) async {
    await ApiService().delete('/topics/$topicId');
    ref.invalidateSelf();
  }

  Future<void> updateTopic(int topicId, String title) async {
    await ApiService().patch('/topics/$topicId', {'title': title});
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(int topicId, bool isCompleted) async {
    await ApiService().patch('/topics/$topicId/complete', {'is_completed': isCompleted});
    ref.invalidateSelf();
  }
}

final topicNotifierProvider =
    AsyncNotifierProviderFamily<TopicNotifier, List<TopicModel>, int>(TopicNotifier.new);

class SubtopicNotifier extends FamilyAsyncNotifier<List<SubtopicModel>, int> {
  @override
  Future<List<SubtopicModel>> build(int topicId) async {
    final data = await ApiService().get('/subtopics/topic/$topicId') as List<dynamic>;
    return data.map((e) => SubtopicModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addSubtopic(String title) async {
    await ApiService().post('/subtopics/', {'topic_id': arg, 'title': title});
    ref.invalidateSelf();
  }

  Future<void> deleteSubtopic(int subtopicId) async {
    await ApiService().delete('/subtopics/$subtopicId');
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(int subtopicId, bool isCompleted) async {
    await ApiService().patch('/subtopics/$subtopicId', {'is_completed': isCompleted});
    ref.invalidateSelf();
  }
}

final subtopicNotifierProvider =
    AsyncNotifierProviderFamily<SubtopicNotifier, List<SubtopicModel>, int>(SubtopicNotifier.new);
