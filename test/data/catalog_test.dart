import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/data/datasources/catalog_repository_impl.dart';
import 'package:marshrut/domain/planner/topological_sort.dart';
import 'package:marshrut/domain/repositories/repositories.dart';

import '../helpers/test_app.dart';

/// Проверка данных каталога: ошибка в JSON обнаружится до запуска приложения.
void main() {
  test('все 4 направления загружаются и корректны', () async {
    final directions = await fileCatalog().loadDirections();
    expect(directions.map((d) => d.id), [
      'flutter',
      'python',
      'english',
      'algorithms',
    ]);

    for (final direction in directions) {
      final topics = direction.topics;
      final ids = topics.map((t) => t.id).toList();
      final reason = 'направление ${direction.id}';

      expect(topics.length, inInclusiveRange(15, 25), reason: reason);
      expect(ids.toSet().length, ids.length, reason: '$reason: дубли id');
      expect(direction.diagnosticTopics.length, greaterThanOrEqualTo(5));

      for (final topic in topics) {
        expect(topic.minutes, greaterThan(0), reason: topic.id);
        expect(topic.level, inInclusiveRange(1, 6), reason: topic.id);
        for (final dep in topic.prerequisites) {
          expect(ids, contains(dep), reason: '${topic.id} → $dep');
        }
        final question = topic.question;
        if (question != null) {
          expect(question.options.length, greaterThanOrEqualTo(2));
          expect(
            question.answerIndex,
            inInclusiveRange(0, question.options.length - 1),
            reason: topic.id,
          );
        }
      }

      // Граф зависимостей ацикличен: сортировка Кана проходит без ошибок.
      expect(topologicalSort(topics), hasLength(topics.length));
    }
  });

  test('повреждённый JSON превращается в понятную ошибку', () async {
    final catalog = CatalogRepositoryImpl((_) async => '{ не json');
    expect(catalog.loadDirections(), throwsA(isA<AppException>()));
  });

  test('каталог читается один раз и кэшируется', () async {
    var reads = 0;
    final catalog = CatalogRepositoryImpl((path) {
      reads++;
      return File(path).readAsString();
    });
    final first = await catalog.loadDirections();
    final second = await catalog.loadDirections();
    expect(identical(first, second), isTrue);
    expect(reads, CatalogRepositoryImpl.files.length);
  });
}
