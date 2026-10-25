import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/document_models.dart';

// ── Search & Filter State ───────────────────────────────────────────────────

class DocumentFilterState {
  final int? roadmapId;
  final int? topicId;
  final String searchQuery;

  const DocumentFilterState({
    this.roadmapId,
    this.topicId,
    this.searchQuery = '',
  });

  DocumentFilterState copyWith({
    int? roadmapId,
    int? topicId,
    String? searchQuery,
    bool clearRoadmap = false,
    bool clearTopic = false,
  }) {
    return DocumentFilterState(
      roadmapId: clearRoadmap ? null : (roadmapId ?? this.roadmapId),
      topicId: clearTopic ? null : (topicId ?? this.topicId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

final documentFilterProvider = StateProvider<DocumentFilterState>((ref) {
  return const DocumentFilterState();
});

// ── Document List Notifier ──────────────────────────────────────────────────

class DocumentsNotifier extends AsyncNotifier<List<DocumentModel>> {
  @override
  Future<List<DocumentModel>> build() async {
    final filter = ref.watch(documentFilterProvider);
    return _fetchDocuments(filter);
  }

  Future<List<DocumentModel>> _fetchDocuments(DocumentFilterState filter) async {
    final params = <String>[];
    if (filter.roadmapId != null) params.add('roadmap_id=${filter.roadmapId}');
    if (filter.topicId != null) params.add('topic_id=${filter.topicId}');
    if (filter.searchQuery.trim().isNotEmpty) {
      params.add('q=${Uri.encodeComponent(filter.searchQuery.trim())}');
    }

    final queryStr = params.isNotEmpty ? '?${params.join('&')}' : '';
    final response = await ApiService().get('/documents/$queryStr') as List<dynamic>;
    return response.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refreshDocuments() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final filter = ref.read(documentFilterProvider);
      return _fetchDocuments(filter);
    });
  }

  Future<DocumentModel> addDocument({
    required String title,
    required String docType,
    required String content,
    int? topicId,
    int? roadmapId,
    String? filePath,
  }) async {
    final payload = {
      'title': title.trim(),
      'doc_type': docType,
      'content': content.trim(),
      if (topicId != null) 'topic_id': topicId,
      if (roadmapId != null) 'roadmap_id': roadmapId,
      if (filePath != null && filePath.isNotEmpty) 'file_path': filePath,
    };

    final res = await ApiService().post('/documents/', payload) as Map<String, dynamic>;
    final created = DocumentModel.fromJson(res);
    await refreshDocuments();
    return created;
  }

  Future<void> deleteDocument(int id) async {
    await ApiService().delete('/documents/$id');
    await refreshDocuments();
  }
}

final documentsNotifierProvider =
    AsyncNotifierProvider<DocumentsNotifier, List<DocumentModel>>(DocumentsNotifier.new);

// ── Document Detail Provider ────────────────────────────────────────────────

final documentDetailProvider = FutureProvider.family<DocumentModel, int>((ref, docId) async {
  final data = await ApiService().get('/documents/$docId') as Map<String, dynamic>;
  return DocumentModel.fromJson(data);
});

final selectedDocumentIdProvider = StateProvider<int?>((ref) => null);

// ── RAG Q&A State Notifier ──────────────────────────────────────────────────

class RAGState {
  final bool isLoading;
  final RAGQueryResult? result;
  final String? errorMessage;

  const RAGState({
    this.isLoading = false,
    this.result,
    this.errorMessage,
  });

  RAGState copyWith({
    bool? isLoading,
    RAGQueryResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return RAGState(
      isLoading: isLoading ?? this.isLoading,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RAGNotifier extends StateNotifier<RAGState> {
  RAGNotifier() : super(const RAGState());

  Future<void> queryRAG({
    required String query,
    List<int>? documentIds,
    int topK = 3,
    String? model,
  }) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final payload = {
        'query': query.trim(),
        'top_k': topK,
        if (documentIds != null && documentIds.isNotEmpty) 'document_ids': documentIds,
        if (model != null && model.isNotEmpty) 'model': model,
      };

      final data = await ApiService().post('/documents/query', payload) as Map<String, dynamic>;
      final result = RAGQueryResult.fromJson(data);
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to process RAG query: $e',
      );
    }
  }

  void clearResult() {
    state = const RAGState();
  }
}

final ragNotifierProvider =
    StateNotifierProvider<RAGNotifier, RAGState>((ref) => RAGNotifier());
