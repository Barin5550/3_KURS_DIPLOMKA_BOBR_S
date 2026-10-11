import 'dart:collection';

import '../entities/topic.dart';

/// В графе тем обнаружен цикл, поэтому порядок изучения построить нельзя.
class CycleDetectedException implements Exception {
  CycleDetectedException(this.topicIds);

  /// Темы, которые остались неупорядоченными (входят в цикл или зависят от него).
  final List<String> topicIds;

  @override
  String toString() =>
      'В зависимостях тем есть цикл: ${topicIds.join(', ')}';
}

/// Топологическая сортировка тем алгоритмом Кана.
///
/// 1. Для каждой темы считаем входящую степень — число её зависимостей
///    внутри переданного набора. Зависимости, которых нет в наборе
///    (например, уже изученные темы), считаются выполненными.
/// 2. Темы с нулевой степенью помещаем в очередь с приоритетом.
/// 3. Извлекаем тему, добавляем в результат и уменьшаем степень у всех тем,
///    которые от неё зависят. Если степень стала нулевой — тема в очередь.
/// 4. Если в результат попали не все темы, в графе есть цикл.
///
/// Очередь упорядочена по уровню сложности, затем по исходной позиции темы,
/// поэтому при одинаковых входных данных результат всегда одинаковый.
/// Сложность — O((V + E) · log V) из-за очереди с приоритетом.
List<Topic> topologicalSort(List<Topic> topics) {
  final index = <String, int>{
    for (var i = 0; i < topics.length; i++) topics[i].id: i,
  };
  final inDegree = List<int>.filled(topics.length, 0);
  final dependents = List.generate(topics.length, (_) => <int>[]);

  for (var i = 0; i < topics.length; i++) {
    for (final prerequisite in topics[i].prerequisites.toSet()) {
      final from = index[prerequisite];
      if (from == null) continue; // зависимость уже изучена или вне плана
      dependents[from].add(i);
      inDegree[i]++;
    }
  }

  int compare(int a, int b) {
    final byLevel = topics[a].level.compareTo(topics[b].level);
    return byLevel != 0 ? byLevel : a.compareTo(b);
  }

  final queue = SplayTreeSet<int>(compare);
  for (var i = 0; i < topics.length; i++) {
    if (inDegree[i] == 0) queue.add(i);
  }

  final result = <Topic>[];
  while (queue.isNotEmpty) {
    final current = queue.first;
    queue.remove(current);
    result.add(topics[current]);
    for (final next in dependents[current]) {
      inDegree[next]--;
      if (inDegree[next] == 0) queue.add(next);
    }
  }

  if (result.length != topics.length) {
    final sorted = result.map((t) => t.id).toSet();
    throw CycleDetectedException(
      topics.where((t) => !sorted.contains(t.id)).map((t) => t.id).toList(),
    );
  }
  return result;
}
