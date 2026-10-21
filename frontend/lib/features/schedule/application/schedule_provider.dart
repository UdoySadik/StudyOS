import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/schedule_model.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

String formatDate(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

final scheduleNotifierProvider =
    AsyncNotifierProviderFamily<ScheduleNotifier, List<ScheduleBlockModel>, String>(
  ScheduleNotifier.new,
);

class ScheduleNotifier extends FamilyAsyncNotifier<List<ScheduleBlockModel>, String> {
  @override
  Future<List<ScheduleBlockModel>> build(String targetDate) async {
    final data = await ApiService().get('/schedule/', queryParams: {'target_date': targetDate})
        as List<dynamic>;
    return data.map((e) => ScheduleBlockModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addBlock({
    required String scheduledDate,
    required String startTime,
    required String endTime,
    required String title,
    int? topicId,
    String? notes,
  }) async {
    await ApiService().post('/schedule/', {
      'scheduled_date': scheduledDate,
      'start_time': startTime,
      'end_time': endTime,
      'title': title,
      'topic_id': topicId,
      'notes': notes,
    });
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(int blockId, bool isCompleted) async {
    await ApiService().patch('/schedule/$blockId/complete', {
      'is_completed': isCompleted,
    });
    ref.invalidateSelf();
  }

  Future<void> deleteBlock(int blockId) async {
    await ApiService().delete('/schedule/$blockId');
    ref.invalidateSelf();
  }

  Future<void> updateBlock(int blockId, Map<String, dynamic> updates) async {
    await ApiService().patch('/schedule/$blockId', updates);
    ref.invalidateSelf();
  }
}
