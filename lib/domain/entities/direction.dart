import 'topic.dart';

/// Направление обучения (например, «Flutter-разработчик») — граф тем.
class Direction {
  const Direction({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorValue,
    required this.topics,
  });

  final String id;
  final String title;
  final String description;

  /// Имя иконки Material (сопоставляется с IconData в слое presentation).
  final String icon;

  /// Цвет направления в формате 0xAARRGGBB.
  final int colorValue;
  final List<Topic> topics;

  int get totalMinutes => topics.fold(0, (sum, t) => sum + t.minutes);

  List<Topic> get diagnosticTopics =>
      topics.where((t) => t.question != null).toList();

  Topic? topicById(String id) {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  factory Direction.fromJson(Map<String, dynamic> json) {
    final hex = (json['color'] as String).replaceFirst('#', '');
    return Direction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      colorValue: int.parse('FF$hex', radix: 16),
      topics: (json['topics'] as List<dynamic>)
          .map((e) => Topic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
