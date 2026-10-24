import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/recall_models.dart';

enum RecallViewMode {
  overview,
  flashcardPlayer,
  quizPlayer,
}

final activeRecallViewModeProvider = StateProvider<RecallViewMode>((ref) => RecallViewMode.overview);
final activeDeckForStudyProvider = StateProvider<DeckModel?>((ref) => null);
final activeQuizForStudyProvider = StateProvider<QuizModel?>((ref) => null);

final decksListProvider =
    AsyncNotifierProvider<DecksListNotifier, List<DeckModel>>(
  DecksListNotifier.new,
);

class DecksListNotifier extends AsyncNotifier<List<DeckModel>> {
  @override
  Future<List<DeckModel>> build() async {
    final res = await ApiService().get('/recall/decks/') as List<dynamic>;
    return res.map((e) => DeckModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GenerateRecallResult> generateFromNote({
    int? topicId,
    String? noteContent,
    int count = 5,
    bool generateFlashcards = true,
    bool generateQuiz = true,
    String? model,
  }) async {
    final payload = {
      if (topicId != null && topicId > 0) 'topic_id': topicId,
      if (noteContent != null && noteContent.trim().isNotEmpty) 'note_content': noteContent.trim(),
      'count': count,
      'generate_flashcards': generateFlashcards,
      'generate_quiz': generateQuiz,
      if (model != null && model.isNotEmpty) 'model': model,
    };

    final res = await ApiService().post('/recall/generate', payload) as Map<String, dynamic>;
    final result = GenerateRecallResult.fromJson(res);

    ref.invalidateSelf();
    ref.invalidate(quizzesListProvider);
    return result;
  }

  Future<void> createDeck(String title, {int? topicId, String? description}) async {
    await ApiService().post('/recall/decks/', {
      'title': title.trim(),
      if (topicId != null && topicId > 0) 'topic_id': topicId,
      if (description != null) 'description': description.trim(),
    });
    ref.invalidateSelf();
  }

  Future<void> deleteDeck(int deckId) async {
    await ApiService().delete('/recall/decks/$deckId');
    ref.invalidateSelf();
  }

  Future<void> addCard(int deckId, String front, String back) async {
    await ApiService().post('/recall/decks/$deckId/cards', {
      'front': front.trim(),
      'back': back.trim(),
    });
    ref.invalidateSelf();
  }

  Future<void> toggleMastery(int cardId, bool isMastered) async {
    await ApiService().patch('/recall/cards/$cardId/mastery?is_mastered=$isMastered', {});
    ref.invalidateSelf();
  }

  Future<void> deleteCard(int cardId) async {
    await ApiService().delete('/recall/cards/$cardId');
    ref.invalidateSelf();
  }
}

final quizzesListProvider =
    AsyncNotifierProvider<QuizzesListNotifier, List<QuizModel>>(
  QuizzesListNotifier.new,
);

class QuizzesListNotifier extends AsyncNotifier<List<QuizModel>> {
  @override
  Future<List<QuizModel>> build() async {
    final res = await ApiService().get('/recall/quizzes/') as List<dynamic>;
    return res.map((e) => QuizModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createQuiz(String title, {int? topicId, String? description}) async {
    await ApiService().post('/recall/quizzes/', {
      'title': title.trim(),
      if (topicId != null && topicId > 0) 'topic_id': topicId,
      if (description != null) 'description': description.trim(),
    });
    ref.invalidateSelf();
  }

  Future<void> deleteQuiz(int quizId) async {
    await ApiService().delete('/recall/quizzes/$quizId');
    ref.invalidateSelf();
  }

  Future<void> addQuestion(int quizId, String question, List<String> options, int correctIndex, {String? explanation}) async {
    await ApiService().post('/recall/quizzes/$quizId/questions', {
      'question': question.trim(),
      'options': options,
      'correct_index': correctIndex,
      if (explanation != null) 'explanation': explanation.trim(),
    });
    ref.invalidateSelf();
  }

  Future<void> deleteQuestion(int questionId) async {
    await ApiService().delete('/recall/questions/$questionId');
    ref.invalidateSelf();
  }
}
