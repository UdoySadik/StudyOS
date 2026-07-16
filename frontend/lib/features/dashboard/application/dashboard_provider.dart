import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/dashboard_summary.dart';
import '../../roadmap/application/roadmap_provider.dart';

final dashboardProvider = FutureProvider.autoDispose<DashboardSummary?>((ref) async {
  // Watch selected roadmap
  final selectedId = ref.watch(selectedRoadmapIdProvider);
  if (selectedId == null) return null;

  final data = await ApiService().get('/dashboard/$selectedId') as Map<String, dynamic>;
  return DashboardSummary.fromJson(data);
});
