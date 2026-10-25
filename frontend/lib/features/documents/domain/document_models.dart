class DocumentChunkModel {
  final int id;
  final int documentId;
  final int chunkIndex;
  final int pageNumber;
  final String content;
  final int wordCount;
  final String? createdAt;

  const DocumentChunkModel({
    required this.id,
    required this.documentId,
    required this.chunkIndex,
    required this.pageNumber,
    required this.content,
    required this.wordCount,
    this.createdAt,
  });

  factory DocumentChunkModel.fromJson(Map<String, dynamic> json) {
    return DocumentChunkModel(
      id: json['id'] as int,
      documentId: json['document_id'] as int,
      chunkIndex: json['chunk_index'] as int? ?? 0,
      pageNumber: json['page_number'] as int? ?? 1,
      content: json['content'] as String? ?? '',
      wordCount: json['word_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'chunk_index': chunkIndex,
      'page_number': pageNumber,
      'content': content,
      'word_count': wordCount,
      'created_at': createdAt,
    };
  }
}

class DocumentModel {
  final int id;
  final int? roadmapId;
  final int? topicId;
  final String? topicTitle;
  final String? roadmapTitle;
  final String title;
  final String docType;
  final String? filePath;
  final int totalPages;
  final int totalChunks;
  final String? createdAt;
  final List<DocumentChunkModel> chunks;

  const DocumentModel({
    required this.id,
    this.roadmapId,
    this.topicId,
    this.topicTitle,
    this.roadmapTitle,
    required this.title,
    required this.docType,
    this.filePath,
    required this.totalPages,
    required this.totalChunks,
    this.createdAt,
    this.chunks = const [],
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final rawChunks = json['chunks'] as List<dynamic>? ?? [];
    return DocumentModel(
      id: json['id'] as int,
      roadmapId: json['roadmap_id'] as int?,
      topicId: json['topic_id'] as int?,
      topicTitle: json['topic_title'] as String?,
      roadmapTitle: json['roadmap_title'] as String?,
      title: json['title'] as String? ?? 'Untitled Document',
      docType: json['doc_type'] as String? ?? 'textbook',
      filePath: json['file_path'] as String?,
      totalPages: json['total_pages'] as int? ?? 1,
      totalChunks: json['total_chunks'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      chunks: rawChunks.map((e) => DocumentChunkModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roadmap_id': roadmapId,
      'topic_id': topicId,
      'topic_title': topicTitle,
      'roadmap_title': roadmapTitle,
      'title': title,
      'doc_type': docType,
      'file_path': filePath,
      'total_pages': totalPages,
      'total_chunks': totalChunks,
      'created_at': createdAt,
      'chunks': chunks.map((c) => c.toJson()).toList(),
    };
  }
}

class CitationModel {
  final int documentId;
  final String documentTitle;
  final int chunkIndex;
  final int pageNumber;
  final String snippet;
  final double relevanceScore;

  const CitationModel({
    required this.documentId,
    required this.documentTitle,
    required this.chunkIndex,
    required this.pageNumber,
    required this.snippet,
    required this.relevanceScore,
  });

  factory CitationModel.fromJson(Map<String, dynamic> json) {
    return CitationModel(
      documentId: json['document_id'] as int,
      documentTitle: json['document_title'] as String? ?? '',
      chunkIndex: json['chunk_index'] as int? ?? 0,
      pageNumber: json['page_number'] as int? ?? 1,
      snippet: json['snippet'] as String? ?? '',
      relevanceScore: (json['relevance_score'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'document_id': documentId,
      'document_title': documentTitle,
      'chunk_index': chunkIndex,
      'page_number': pageNumber,
      'snippet': snippet,
      'relevance_score': relevanceScore,
    };
  }
}

class RAGQueryResult {
  final String query;
  final String answerMarkdown;
  final List<CitationModel> citations;
  final String modelUsed;
  final int retrievalCount;

  const RAGQueryResult({
    required this.query,
    required this.answerMarkdown,
    this.citations = const [],
    required this.modelUsed,
    required this.retrievalCount,
  });

  factory RAGQueryResult.fromJson(Map<String, dynamic> json) {
    final rawCitations = json['citations'] as List<dynamic>? ?? [];
    return RAGQueryResult(
      query: json['query'] as String? ?? '',
      answerMarkdown: json['answer_markdown'] as String? ?? '',
      citations: rawCitations.map((e) => CitationModel.fromJson(e as Map<String, dynamic>)).toList(),
      modelUsed: json['model_used'] as String? ?? 'builtin-offline',
      retrievalCount: json['retrieval_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'answer_markdown': answerMarkdown,
      'citations': citations.map((c) => c.toJson()).toList(),
      'model_used': modelUsed,
      'retrieval_count': retrievalCount,
    };
  }
}
