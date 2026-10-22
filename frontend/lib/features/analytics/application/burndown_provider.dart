import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/burndown_model.dart';

final burndownProvider =
    AsyncNotifierProviderFamily<BurndownNotifier, RoadmapBurndownModel, int>(
  BurndownNotifier.new,
);

class BurndownNotifier extends FamilyAsyncNotifier<RoadmapBurndownModel, int> {
  @override
  Future<RoadmapBurndownModel> build(int roadmapId) async {
    final res = await ApiService().get('/analytics/burndown/$roadmapId')
        as Map<String, dynamic>;
    return RoadmapBurndownModel.fromJson(res);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
