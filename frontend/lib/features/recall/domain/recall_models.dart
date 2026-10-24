class FlashcardModel {
  final int id;
  final int deckId;
  final String front;
  final String back;
  final bool isMastered;
  final int reviewCount;
  final DateTime? createdAt;

  const FlashcardModel({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    required this.isMastered,
    this.reviewCount = 0,
    this.createdAt,
  });

  factory FlashcardModel.fromJson(Map<String, dynamic> json) {
    return FlashcardModel(
      id: json['id'] as int,
      deckId: json['deck_id'] as int,
      front: json['front'] as String? ?? '',
      back: json['back'] as String? ?? '',
      isMastered: json['is_mastered'] as bool? ?? false,
      reviewCount: json['review_count'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deck_id': deckId,
      'front': front,
      'back': back,
      'is_mastered': isMastered,
      'review_count': reviewCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  FlashcardModel copyWith({
    int? id,
    int? deckId,
    String? front,
    String? back,
    bool? isMastered,
    int? reviewCount,
    DateTime? createdAt,
  }) {
    return FlashcardModel(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      isMastered: isMastered ?? this.isMastered,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class DeckModel {
  final int id;
  final int? topicId;
  final String? topicTitle;
  final String title;
  final String? description;
  final int totalCards;
  final int masteredCards;
  final DateTime? createdAt;
  final List<FlashcardModel> cards;

  const DeckModel({
    required this.id,
    this.topicId,
    this.topicTitle,
    required this.title,
    this.description,
    this.totalCards = 0,
    this.masteredCards = 0,
    this.createdAt,
    this.cards = const [],
  });

  factory DeckModel.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'] as List<dynamic>? ?? [];
    final parsedCards = rawCards.map((c) => FlashcardModel.fromJson(c as Map<String, dynamic>)).toList();
    final masteredCount = parsedCards.where((c) => c.isMastered).length;
    return DeckModel(
      id: json['id'] as int,
      topicId: json['topic_id'] as int?,
      topicTitle: json['topic_title'] as String?,
      title: json['title'] as String? ?? 'Untitled Deck',
      description: json['description'] as String?,
      totalCards: json['total_cards'] as int? ?? parsedCards.length,
      masteredCards: json['mastered_cards'] as int? ?? masteredCount,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      cards: parsedCards,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'topic_title': topicTitle,
      'title': title,
      'description': description,
      'total_cards': totalCards,
      'mastered_cards': masteredCards,
      'created_at': createdAt?.toIso8601String(),
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }

  double get masteryPercent => totalCards > 0 ? (masteredCards / totalCards) : 0.0;

  DeckModel copyWith({
    int? id,
    int? topicId,
    String? topicTitle,
    String? title,
    String? description,
    int? totalCards,
    int? masteredCards,
    DateTime? createdAt,
    List<FlashcardModel>? cards,
  }) {
    return DeckModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      topicTitle: topicTitle ?? this.topicTitle,
      title: title ?? this.title,
      description: description ?? this.description,
      totalCards: totalCards ?? this.totalCards,
      masteredCards: masteredCards ?? this.masteredCards,
      createdAt: createdAt ?? this.createdAt,
      cards: cards ?? this.cards,
    );
  }
}

class QuizQuestionModel {
  final int id;
  final int quizId;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  const QuizQuestionModel({
    required this.id,
    required this.quizId,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return QuizQuestionModel(
      id: json['id'] as int,
      quizId: json['quiz_id'] as int,
      question: json['question'] as String? ?? '',
      options: rawOptions.map((e) => e.toString()).toList(),
      correctIndex: json['correct_index'] as int? ?? 0,
      explanation: json['explanation'] as String?,
    );
  }

  String get correctOption => options.isNotEmpty && correctIndex >= 0 && correctIndex < options.length
      ? options[correctIndex]
      : '';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question': question,
      'options': options,
      'correct_index': correctIndex,
      'explanation': explanation,
    };
  }
}

class QuizModel {
  final int id;
  final int? topicId;
  final String? topicTitle;
  final String title;
  final String? description;
  final int questionsCount;
  final DateTime? createdAt;
  final List<QuizQuestionModel> questions;

  const QuizModel({
    required this.id,
    this.topicId,
    this.topicTitle,
    required this.title,
    this.description,
    this.questionsCount = 0,
    this.createdAt,
    this.questions = const [],
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return QuizModel(
      id: json['id'] as int,
      topicId: json['topic_id'] as int?,
      topicTitle: json['topic_title'] as String?,
      title: json['title'] as String? ?? 'Untitled Quiz',
      description: json['description'] as String?,
      questionsCount: json['questions_count'] as int? ?? rawQuestions.length,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      questions: rawQuestions.map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'topic_title': topicTitle,
      'title': title,
      'description': description,
      'questions_count': questionsCount,
      'created_at': createdAt?.toIso8601String(),
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }
}

class GenerateRecallResult {
  final DeckModel? deck;
  final QuizModel? quiz;
  final String modelUsed;
  final int generatedCardsCount;
  final int generatedQuestionsCount;

  const GenerateRecallResult({
    this.deck,
    this.quiz,
    required this.modelUsed,
    required this.generatedCardsCount,
    required this.generatedQuestionsCount,
  });

  factory GenerateRecallResult.fromJson(Map<String, dynamic> json) {
    return GenerateRecallResult(
      deck: json['deck'] != null ? DeckModel.fromJson(json['deck'] as Map<String, dynamic>) : null,
      quiz: json['quiz'] != null ? QuizModel.fromJson(json['quiz'] as Map<String, dynamic>) : null,
      modelUsed: json['model_used'] as String? ?? 'builtin-offline',
      generatedCardsCount: json['generated_cards_count'] as int? ?? 0,
      generatedQuestionsCount: json['generated_questions_count'] as int? ?? 0,
    );
  }
}
