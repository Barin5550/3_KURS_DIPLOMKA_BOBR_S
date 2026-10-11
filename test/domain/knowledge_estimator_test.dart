import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/domain/entities/topic.dart';
import 'package:marshrut/domain/planner/knowledge_estimator.dart';

Topic t(String id, [List<String> deps = const []]) => Topic(
  id: id,
  title: id,
  minutes: 60,
  category: 'Тест',
  prerequisites: deps,
);

void main() {
  // dart → oop → widgets → riverpod
  //      ↘ async ↗
  final topics = [
    t('dart'),
    t('oop', ['dart']),
    t('async', ['dart']),
    t('widgets', ['oop']),
    t('riverpod', ['widgets', 'async']),
  ];
  const estimator = KnowledgeEstimator();

  test('без ответов ничего не известно', () {
    expect(estimator.knownTopics(topics, {}), isEmpty);
  });

  test('верный ответ отмечает тему и всех её предшественников', () {
    final known = estimator.knownTopics(topics, {'widgets': true});
    expect(known, {'widgets', 'oop', 'dart'});
  });

  test('неверный ответ исключает тему, даже если её покрыла сложная тема', () {
    final known = estimator.knownTopics(topics, {
      'riverpod': true,
      'async': false,
    });
    expect(known, {'riverpod', 'widgets', 'oop', 'dart'});
    expect(known.contains('async'), isFalse);
  });

  test('неизвестные идентификаторы игнорируются', () {
    expect(estimator.knownTopics(topics, {'unknown': true}), isEmpty);
  });
}
