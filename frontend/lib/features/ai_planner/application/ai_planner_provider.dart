import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../../projects/application/projects_provider.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../domain/study_plan_model.dart';

final ollamaStatusProvider = FutureProvider<OllamaStatusModel>((ref) async {
  final res = await ApiService().get('/ai/ollama/status') as Map<String, dynamic>;
  return OllamaStatusModel.fromJson(res);
});

final selectedOllamaModelProvider = StateProvider<String?>((ref) => null);

final selectedPlanIdProvider = StateProvider<int?>((ref) => null);

final studyPlansListProvider =
    AsyncNotifierProvider<StudyPlansListNotifier, List<StudyPlanModel>>(
  StudyPlansListNotifier.new,
);

class StudyPlansListNotifier extends AsyncNotifier<List<StudyPlanModel>> {
  @override
  Future<List<StudyPlanModel>> build() async {
    final res = await ApiService().get('/ai/plans/') as List<dynamic>;
    return res.map((e) => StudyPlanModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StudyPlanModel> generatePlan({
    required String subject,
    String proficiency = 'intermediate',
    int hoursPerWeek = 10,
    int targetWeeks = 4,
    String? focusArea,
    String? customInstructions,
    String? model,
    int? roadmapId,
  }) async {
    final payload = {
      'subject': subject.trim(),
      'proficiency': proficiency,
      'hours_per_week': hoursPerWeek,
      'target_weeks': targetWeeks,
      if (focusArea != null && focusArea.trim().isNotEmpty) 'focus_area': focusArea.trim(),
      if (customInstructions != null && customInstructions.trim().isNotEmpty)
        'custom_instructions': customInstructions.trim(),
      if (model != null && model.trim().isNotEmpty) 'model': model.trim(),
      if (roadmapId != null && roadmapId > 0) 'roadmap_id': roadmapId,
    };

    final res = await ApiService().post('/ai/plans/generate', payload) as Map<String, dynamic>;
    final newPlan = StudyPlanModel.fromJson(res);
    ref.read(selectedPlanIdProvider.notifier).state = newPlan.id;
    ref.invalidateSelf();
    return newPlan;
  }

  Future<void> importRoadmap(int planId) async {
    await ApiService().post('/ai/plans/$planId/import-roadmap', {});
    // Invalidate roadmaps and projects so UI reflects newly created syllabus and projects immediately
    ref.invalidate(roadmapsProvider);
    ref.invalidate(roadmapNotifierProvider);
    ref.invalidate(projectsListProvider);
    ref.invalidateSelf();
  }

  Future<void> deletePlan(int planId) async {
    await ApiService().delete('/ai/plans/$planId');
    final currentSelected = ref.read(selectedPlanIdProvider);
    if (currentSelected == planId) {
      ref.read(selectedPlanIdProvider.notifier).state = null;
    }
    ref.invalidateSelf();
  }
}

final selectedPlanProvider = Provider<StudyPlanModel?>((ref) {
  final plansAsync = ref.watch(studyPlansListProvider);
  final selectedId = ref.watch(selectedPlanIdProvider);
  final plans = plansAsync.valueOrNull ?? [];

  if (plans.isEmpty) return null;
  if (selectedId == null) return plans.first;
  return plans.firstWhere(
    (p) => p.id == selectedId,
    orElse: () => plans.first,
  );
});
