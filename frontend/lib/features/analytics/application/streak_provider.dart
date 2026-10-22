import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/streak_model.dart';

final streakProvider =
    AsyncNotifierProvider<StreakNotifier, StreakSummaryModel>(StreakNotifier.new);

class StreakNotifier extends AsyncNotifier<StreakSummaryModel> {
  @override
  Future<StreakSummaryModel> build() async {
    final res = await ApiService().get('/analytics/streak') as Map<String, dynamic>;
    return StreakSummaryModel.fromJson(res);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
