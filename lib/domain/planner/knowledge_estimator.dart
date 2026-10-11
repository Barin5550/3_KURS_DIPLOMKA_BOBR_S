import '../entities/topic.dart';

/// Определяет, какие темы пользователь уже знает, по ответам диагностического теста.
///
/// Правила:
/// * верный ответ по теме означает, что известны сама тема и все её
///   предшественники в графе (кто знает Riverpod, знает и основы Dart);
/// * неверный ответ (или «Не знаю») означает, что тема не известна, даже если
///   её «покрыл» верный ответ по более сложной теме — явный провал важнее.
class KnowledgeEstimator {
  const KnowledgeEstimator();

  /// [answers] — для каждой темы с вопросом: `true`, если ответ верный.
  Set<String> knownTopics(List<Topic> topics, Map<String, bool> answers) {
    final byId = {for (final t in topics) t.id: t};
    final known = <String>{};

    void markWithAncestors(String id) {
      final stack = [id];
      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        if (!known.add(current)) continue;
        final topic = byId[current];
        if (topic != null) stack.addAll(topic.prerequisites);
      }
    }

    answers.forEach((topicId, correct) {
      if (correct && byId.containsKey(topicId)) markWithAncestors(topicId);
    });

    final failed = answers.entries.where((e) => !e.value).map((e) => e.key);
    known.removeAll(failed);
    known.retainAll(byId.keys);
    return known;
  }
}
