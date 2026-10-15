// Файл topic.dart — сущности «тема», «учебный материал» и «вопрос теста».
// Слой: domain. Темы каталога читаются из assets/catalog/*.json через
// Topic.fromJson (вызывается из Direction.fromJson); свои темы
// пользователя создаёт TopicRepositoryImpl (data) с isCustom = true.
// Темы используют планировщик (domain/planner) и экраны тем и онбординга.
/// Учебный материал по теме (ссылка на документацию, статью, курс).
class Resource {
  /// Создаёт материал с названием и ссылкой.
  const Resource({required this.title, required this.url});

  /// Название материала для списка.
  final String title;

  /// Адрес страницы в интернете.
  final String url;

  /// Создаёт материал из JSON вида `{"title": ..., "url": ...}`.
  factory Resource.fromJson(Map<String, dynamic> json) =>
      Resource(title: json['title'] as String, url: json['url'] as String);
}

/// Вопрос диагностического теста, привязанный к теме.
///
/// По ответам на такие вопросы определяется, какие темы пользователь
/// уже знает; известные темы не попадают в план.
class DiagnosticQuestion {
  /// Создаёт вопрос с вариантами ответа.
  const DiagnosticQuestion({
    required this.text,
    required this.options,
    required this.answerIndex,
  });

  /// Текст вопроса.
  final String text;

  /// Варианты ответа.
  final List<String> options;

  /// Индекс правильного варианта в [options].
  final int answerIndex;

  /// Создаёт вопрос из JSON; номер правильного ответа лежит в ключе
  /// `answer`.
  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) =>
      DiagnosticQuestion(
        text: json['text'] as String,
        // cast<String>() — приводим список из JSON к списку строк.
        options: (json['options'] as List<dynamic>).cast<String>(),
        answerIndex: json['answer'] as int,
      );
}

/// Тема — вершина графа направления.
///
/// Ребро графа задаётся списком [prerequisites]: тему можно изучать только
/// после того, как изучены все темы из этого списка.
class Topic {
  /// Создаёт тему. Необязательные поля по умолчанию: пустое описание,
  /// уровень 1, без зависимостей, материалов и вопроса, тема из каталога.
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

  /// Строковый идентификатор темы, например `fl_dart_syntax`.
  final String id;

  /// Название темы.
  final String title;

  /// Подробное описание того, что входит в тему.
  final String description;

  /// Оценка времени на изучение темы в минутах.
  final int minutes;

  /// Уровень сложности (1 — самый простой). Используется для упорядочивания
  /// тем, которые можно изучать одновременно.
  final int level;

  /// Категория (раздел) направления, например «Язык Dart».
  final String category;

  /// id тем, которые нужно изучить раньше этой.
  final List<String> prerequisites;

  /// Ссылки на учебные материалы.
  final List<Resource> resources;

  /// Вопрос для диагностического теста (`null` — темы нет в тесте).
  final DiagnosticQuestion? question;

  /// Тема создана пользователем, а не взята из каталога.
  final bool isCustom;

  /// Длительность темы в часах (может быть дробной).
  double get hours => minutes / 60;

  /// Создаёт тему из JSON-описания в каталоге.
  ///
  /// В JSON длительность указана в часах (`hours`), а в объекте хранится
  /// в минутах. Необязательные ключи получают значения по умолчанию.
  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
    // Обязательные поля.
    id: json['id'] as String,
    title: json['title'] as String,
    // Нет описания — пустая строка (?? — «если null, то…»).
    description: json['description'] as String? ?? '',
    // Часы переводим в минуты и округляем до целого.
    minutes: ((json['hours'] as num) * 60).round(),
    // Нет уровня — считаем первым.
    level: json['level'] as int? ?? 1,
    category: json['category'] as String,
    // Список зависимостей; если ключа нет — пустой список.
    prerequisites: (json['prerequisites'] as List<dynamic>? ?? const [])
        .cast<String>(),
    // Материалы: каждый элемент превращаем в объект Resource.
    resources: (json['resources'] as List<dynamic>? ?? const [])
        .map((e) => Resource.fromJson(e as Map<String, dynamic>))
        .toList(),
    // Вопрос теста есть не у всех тем.
    question: json['question'] == null
        ? null
        : DiagnosticQuestion.fromJson(json['question'] as Map<String, dynamic>),
  );

  /// Короткое текстовое представление для отладки: `Topic(id)`.
  @override
  String toString() => 'Topic($id)';
}
