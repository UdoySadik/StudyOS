import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/note_model.dart';

final allNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  final data = await ApiService().get('/notes/') as List<dynamic>;
  return data.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)).toList();
});

final topicNoteProvider = FutureProvider.family<NoteModel?, int>((ref, topicId) async {
  try {
    final data = await ApiService().get('/notes/topic/$topicId') as Map<String, dynamic>;
    return NoteModel.fromJson(data);
  } catch (e) {
    // If 404, return null (meaning no note exists yet)
    return null;
  }
});

class TopicNoteNotifier extends FamilyAsyncNotifier<NoteModel?, int> {
  Timer? _debounceTimer;

  @override
  Future<NoteModel?> build(int topicId) async {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    try {
      final data = await ApiService().get('/notes/topic/$topicId') as Map<String, dynamic>;
      return NoteModel.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Saves the note instantly
  Future<void> saveNoteImmediately(String content) async {
    _debounceTimer?.cancel();
    final data = await ApiService().put('/notes/topic/$arg', {
      'content': content,
    }) as Map<String, dynamic>;
    
    state = AsyncData(NoteModel.fromJson(data));
    ref.invalidate(allNotesProvider);
  }

  /// Debounced note save (500ms default)
  void saveNoteDebounced(String content) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      await saveNoteImmediately(content);
    });
  }
}


final topicNoteNotifierProvider =
    AsyncNotifierProviderFamily<TopicNoteNotifier, NoteModel?, int>(TopicNoteNotifier.new);
