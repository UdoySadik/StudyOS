import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/study_hours_model.dart';

class StudyHoursFilter {
  final int year;
  final int month;
  final int? roadmapId;

  const StudyHoursFilter({
    required this.year,
    required this.month,
    this.roadmapId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyHoursFilter &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          roadmapId == other.roadmapId;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ (roadmapId?.hashCode ?? 0);
}

final studyHoursMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final studyHoursProvider =
    AsyncNotifierProviderFamily<StudyHoursNotifier, MonthlyStudyHoursModel, StudyHoursFilter>(
  StudyHoursNotifier.new,
);

class StudyHoursNotifier
    extends FamilyAsyncNotifier<MonthlyStudyHoursModel, StudyHoursFilter> {
  @override
  Future<MonthlyStudyHoursModel> build(StudyHoursFilter arg) async {
    String endpoint = '/analytics/study-hours?year=${arg.year}&month=${arg.month}';
    if (arg.roadmapId != null) {
      endpoint += '&roadmap_id=${arg.roadmapId}';
    }
    final res = await ApiService().get(endpoint) as Map<String, dynamic>;
    return MonthlyStudyHoursModel.fromJson(res);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
