import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../../roadmap/application/roadmap_provider.dart';
import '../domain/goal_model.dart';

final goalsProvider = FutureProvider<List<GoalModel>>((ref) async {
  final roadmapId = ref.watch(selectedRoadmapIdProvider);
  if (roadmapId == null) return [];
  final data = await ApiService().get('/goals/roadmap/$roadmapId') as List<dynamic>;
  return data.map((e) => GoalModel.fromJson(e as Map<String, dynamic>)).toList();
});

class GoalNotifier extends AutoDisposeAsyncNotifier<List<GoalModel>> {
  @override
  Future<List<GoalModel>> build() async {
    final roadmapId = ref.watch(selectedRoadmapIdProvider);
    if (roadmapId == null) return [];
    final data = await ApiService().get('/goals/roadmap/$roadmapId') as List<dynamic>;
    return data.map((e) => GoalModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setGoal(String targetDate) async {
    final roadmapId = ref.read(selectedRoadmapIdProvider);
    if (roadmapId == null) return;
    await ApiService().post('/goals/', {
      'roadmap_id': roadmapId,
      'target_date': targetDate,
    });
    ref.invalidateSelf();
  }

  Future<void> updateGoal(int goalId, String targetDate) async {
    await ApiService().patch('/goals/$goalId', {
      'target_date': targetDate,
    });
    ref.invalidateSelf();
  }

  Future<void> deleteGoal(int goalId) async {
    await ApiService().delete('/goals/$goalId');
    ref.invalidateSelf();
  }
}

final goalNotifierProvider =
    AutoDisposeAsyncNotifierProvider<GoalNotifier, List<GoalModel>>(GoalNotifier.new);
