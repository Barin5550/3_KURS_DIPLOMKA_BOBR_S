/// Учебный материал по теме (ссылка на документацию, статью, курс).
class Resource {
  const Resource({required this.title, required this.url});

  final String title;
  final String url;

  factory Resource.fromJson(Map<String, dynamic> json) =>
      Resource(title: json['title'] as String, url: json['url'] as String);
}

/// Вопрос диагностического теста, привязанный к теме.
class DiagnosticQuestion {
  const DiagnosticQuestion({
    required this.text,
    required this.options,
    required this.answerIndex,
  });

  final String text;
  final List<String> options;

  /// Индекс правильного варианта в [options].
  final int answerIndex;

  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) =>
      DiagnosticQuestion(
        text: json['text'] as String,
        options: (json['options'] as List<dynamic>).cast<String>(),
        answerIndex: json['answer'] as int,
      );
}

/// Тема — вершина графа направления.
///
/// Ребро графа задаётся списком [prerequisites]: тему можно изучать только
/// после того, как изучены все темы из этого списка.
class Topic {
  const Topic({
    required this.id,
    required this.title,
    required this.minutes,
    required this.category,
    this.description = '',
    this.level = 1,
    this.prerequisites = const [],
    this.resources = const [],
    this.question,
    this.isCustom = false,
  });

  final String id;
  final String title;
  final String description;

  /// Оценка времени на изучение темы в минутах.
  final int minutes;

  /// Уровень сложности (1 — самый простой). Используется для упорядочивания
  /// тем, которые можно изучать одновременно.
  final int level;
  final String category;
  final List<String> prerequisites;
  final List<Resource> resources;
  final DiagnosticQuestion? question;

  /// Тема создана пользователем, а не взята из каталога.
  final bool isCustom;

  double get hours => minutes / 60;

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    minutes: ((json['hours'] as num) * 60).round(),
    level: json['level'] as int? ?? 1,
    category: json['category'] as String,
    prerequisites: (json['prerequisites'] as List<dynamic>? ?? const [])
        .cast<String>(),
    resources: (json['resources'] as List<dynamic>? ?? const [])
        .map((e) => Resource.fromJson(e as Map<String, dynamic>))
        .toList(),
    question: json['question'] == null
        ? null
        : DiagnosticQuestion.fromJson(json['question'] as Map<String, dynamic>),
  );

  @override
  String toString() => 'Topic($id)';
}
