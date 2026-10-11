// Файл direction.dart — сущность «направление обучения» (Direction).
// Слой: domain. Направления с темами хранятся в JSON-файлах
// assets/catalog/*.json; CatalogRepositoryImpl (data/datasources) читает их
// через Direction.fromJson. Используются в онбординге, темах и плане.
import 'topic.dart';

/// Направление обучения (например, «Flutter-разработчик») — граф тем.
///
/// Граф — набор вершин (темы) и связей между ними (какая тема требует
/// какую); связи хранятся в [Topic.prerequisites].
class Direction {
  /// Создаёт направление со всеми полями.
  const Direction({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorValue,
    required this.topics,
  });

  /// Строковый идентификатор направления, например `flutter`.
  final String id;

  /// Название направления для экрана.
  final String title;

  /// Краткое описание направления.
  final String description;

  /// Имя иконки Material (сопоставляется с IconData в слое presentation).
  final String icon;

  /// Цвет направления в формате 0xAARRGGBB.
  final int colorValue;

  /// Все темы направления.
  final List<Topic> topics;

  /// Общая длительность всех тем в минутах.
  int get totalMinutes => topics.fold(0, (sum, t) => sum + t.minutes);

  /// Темы, у которых есть вопрос для диагностического теста.
  List<Topic> get diagnosticTopics =>
      topics.where((t) => t.question != null).toList();

  /// Ищет тему по [id]; если такой темы нет — возвращает `null`.
  Topic? topicById(String id) {
    // Перебираем темы по порядку и возвращаем первую с нужным id.
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    // Ничего не нашли.
    return null;
  }

  /// Создаёт направление из JSON (разобранного файла каталога).
  factory Direction.fromJson(Map<String, dynamic> json) {
    // Цвет в JSON записан как «#3D5AFE»: убираем решётку.
    final hex = (json['color'] as String).replaceFirst('#', '');
    return Direction(
      // Простые текстовые поля берём как есть.
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      // Добавляем «FF» (полная непрозрачность) и читаем как 16-ричное число.
      colorValue: int.parse('FF$hex', radix: 16),
      // Каждый элемент списка topics превращаем в объект Topic.
      topics: (json['topics'] as List<dynamic>)
          .map((e) => Topic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
