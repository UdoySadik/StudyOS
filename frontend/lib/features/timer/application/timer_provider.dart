import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../../analytics/application/streak_provider.dart';
import '../../analytics/application/study_hours_provider.dart';
import '../domain/study_session_model.dart';

class TimerState {
  final int elapsedSeconds;
  final bool isRunning;
  final int? activeTopicId;
  final String? activeTopicTitle;

  const TimerState({
    this.elapsedSeconds = 0,
    this.isRunning = false,
    this.activeTopicId,
    this.activeTopicTitle,
  });

  TimerState copyWith({
    int? elapsedSeconds,
    bool? isRunning,
    int? activeTopicId,
    String? activeTopicTitle,
    bool clearTopic = false,
  }) {
    return TimerState(
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isRunning: isRunning ?? this.isRunning,
      activeTopicId: clearTopic ? null : (activeTopicId ?? this.activeTopicId),
      activeTopicTitle: clearTopic ? null : (activeTopicTitle ?? this.activeTopicTitle),
    );
  }

  String get formattedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class StudyTimerNotifier extends StateNotifier<TimerState> {
  Timer? _timer;
  final Ref _ref;

  StudyTimerNotifier(this._ref) : super(const TimerState());

  void startTimer(int topicId, String topicTitle) {
    _timer?.cancel();
    state = TimerState(
      elapsedSeconds: 0,
      isRunning: true,
      activeTopicId: topicId,
      activeTopicTitle: topicTitle,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void resumeTimer() {
    if (state.activeTopicId == null) return;
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
  }

  void resetTimer() {
    _timer?.cancel();
    state = const TimerState();
  }

  Future<void> saveAndLogSession(String? notes) async {
    final topicId = state.activeTopicId;
    final duration = state.elapsedSeconds;

    if (topicId != null && duration > 0) {
      await ApiService().post('/study-sessions/', {
        'topic_id': topicId,
        'duration_seconds': duration,
        'notes': notes,
      });

      _ref.invalidate(studySummaryProvider);
      _ref.invalidate(topicStudyStatsProvider(topicId));
      _ref.invalidate(streakProvider);
      _ref.invalidate(studyHoursProvider);
    }

    resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final studyTimerProvider = StateNotifierProvider<StudyTimerNotifier, TimerState>((ref) {
  return StudyTimerNotifier(ref);
});

final studySummaryProvider = FutureProvider<StudySummaryModel>((ref) async {
  final data = await ApiService().get('/study-sessions/summary') as Map<String, dynamic>;
  return StudySummaryModel.fromJson(data);
});

final topicStudyStatsProvider =
    FutureProvider.family<TopicStudyStatsModel, int>((ref, topicId) async {
  final data =
      await ApiService().get('/study-sessions/topic/$topicId') as Map<String, dynamic>;
  return TopicStudyStatsModel.fromJson(data);
});
