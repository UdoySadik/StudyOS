import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/note_ai_models.dart';

final noteAIProvider = Provider<NoteAIService>((ref) => NoteAIService());

class NoteAIService {
  Future<NoteSummarizeResult> summarizeNote({
    int? topicId,
    String? noteContent,
    String summaryStyle = 'key_takeaways',
    int maxBullets = 5,
    String? model,
  }) async {
    final payload = {
      if (topicId != null && topicId > 0) 'topic_id': topicId,
      if (noteContent != null && noteContent.trim().isNotEmpty) 'note_content': noteContent.trim(),
      'summary_style': summaryStyle,
      'max_bullets': maxBullets,
      if (model != null && model.isNotEmpty) 'model': model,
    };

    final res = await ApiService().post('/note-ai/summarize', payload) as Map<String, dynamic>;
    return NoteSummarizeResult.fromJson(res);
  }

  Future<ConceptExplainResult> explainConcept({
    required String concept,
    String? context,
    String depth = 'intermediate',
    String? model,
  }) async {
    final payload = {
      'concept': concept.trim(),
      if (context != null && context.trim().isNotEmpty) 'context': context.trim(),
      'depth': depth,
      if (model != null && model.isNotEmpty) 'model': model,
    };

    final res = await ApiService().post('/note-ai/explain', payload) as Map<String, dynamic>;
    return ConceptExplainResult.fromJson(res);
  }
}
