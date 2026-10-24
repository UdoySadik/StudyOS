class NoteSummarizeResult {
  final String summaryMarkdown;
  final List<String> keyTakeaways;
  final String modelUsed;
  final int wordCount;
  final double readingTimeMinutes;

  const NoteSummarizeResult({
    required this.summaryMarkdown,
    this.keyTakeaways = const [],
    required this.modelUsed,
    this.wordCount = 0,
    this.readingTimeMinutes = 0.0,
  });

  factory NoteSummarizeResult.fromJson(Map<String, dynamic> json) {
    final rawTakeaways = json['key_takeaways'] as List<dynamic>? ?? [];
    return NoteSummarizeResult(
      summaryMarkdown: json['summary_markdown'] as String? ?? '',
      keyTakeaways: rawTakeaways.map((e) => e.toString()).toList(),
      modelUsed: json['model_used'] as String? ?? 'builtin-offline',
      wordCount: json['word_count'] as int? ?? 0,
      readingTimeMinutes: (json['reading_time_minutes'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary_markdown': summaryMarkdown,
      'key_takeaways': keyTakeaways,
      'model_used': modelUsed,
      'word_count': wordCount,
      'reading_time_minutes': readingTimeMinutes,
    };
  }
}

class ConceptExplainResult {
  final String concept;
  final String depth;
  final String explanationMarkdown;
  final List<String> keyPoints;
  final String? analogy;
  final String? exampleSnippet;
  final String modelUsed;

  const ConceptExplainResult({
    required this.concept,
    required this.depth,
    required this.explanationMarkdown,
    this.keyPoints = const [],
    this.analogy,
    this.exampleSnippet,
    required this.modelUsed,
  });

  factory ConceptExplainResult.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['key_points'] as List<dynamic>? ?? [];
    return ConceptExplainResult(
      concept: json['concept'] as String? ?? '',
      depth: json['depth'] as String? ?? 'intermediate',
      explanationMarkdown: json['explanation_markdown'] as String? ?? '',
      keyPoints: rawPoints.map((e) => e.toString()).toList(),
      analogy: json['analogy'] as String?,
      exampleSnippet: json['example_snippet'] as String?,
      modelUsed: json['model_used'] as String? ?? 'builtin-offline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'concept': concept,
      'depth': depth,
      'explanation_markdown': explanationMarkdown,
      'key_points': keyPoints,
      'analogy': analogy,
      'example_snippet': exampleSnippet,
      'model_used': modelUsed,
    };
  }
}
