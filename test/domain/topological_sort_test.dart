import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/domain/entities/topic.dart';
import 'package:marshrut/domain/planner/topological_sort.dart';

Topic t(String id, {List<String> deps = const [], int level = 1}) => Topic(
  id: id,
  title: id,
  minutes: 60,
  category: 'Тест',
  level: level,
  prerequisites: deps,
);

List<String> ids(List<Topic> topics) => topics.map((t) => t.id).toList();

void main() {
  group('topologicalSort (алгоритм Кана)', () {
    test('каждая тема идёт после всех своих зависимостей', () {
      final topics = [
        t('riverpod', deps: ['widgets', 'async']),
        t('widgets', deps: ['dart']),
        t('async', deps: ['dart']),
        t('dart'),
      ];

      final order = ids(topologicalSort(topics));

      expect(order.first, 'dart');
      expect(order.last, 'riverpod');
      for (final topic in topics) {
        for (final dep in topic.prerequisites) {
          expect(
            order.indexOf(dep) < order.indexOf(topic.id),
            isTrue,
            reason: '$dep должна идти раньше ${topic.id}',
          );
        }
      }
    });

    test('независимые темы упорядочены по уровню, затем по исходной позиции', () {
      final topics = [
        t('hard', level: 3),
        t('easy_b', level: 1),
        t('medium', level: 2),
        t('easy_a', level: 1),
      ];

      expect(ids(topologicalSort(topics)), [
        'easy_b',
        'easy_a',
        'medium',
        'hard',
      ]);
    });

    test('зависимость, которой нет в наборе, считается выполненной', () {
      final topics = [
        t('b', deps: ['known_topic']),
        t('a'),
      ];

      expect(ids(topologicalSort(topics)), ['b', 'a']);
    });

    test('повторяющаяся зависимость не ломает подсчёт степени', () {
      final topics = [
        t('b', deps: ['a', 'a']),
        t('a'),
      ];

      expect(ids(topologicalSort(topics)), ['a', 'b']);
    });

    test('пустой список даёт пустой результат', () {
      expect(topologicalSort(const []), isEmpty);
    });

    test('цикл в графе обнаруживается', () {
      final topics = [
        t('a', deps: ['c']),
        t('b', deps: ['a']),
        t('c', deps: ['b']),
        t('free'),
      ];

      expect(
        () => topologicalSort(topics),
        throwsA(
          isA<CycleDetectedException>().having(
            (e) => e.topicIds,
            'topicIds',
            unorderedEquals(['a', 'b', 'c']),
          ),
        ),
      );
    });
  });
}
