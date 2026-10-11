// Пример работы алгоритма для главы 2 курсовой (п. 2.4, таблица 2.4).
//
// Запуск:  dart run tool/print_schedule_example.dart
// ignore_for_file: avoid_print

import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/entities/topic.dart';
import 'package:marshrut/domain/planner/plan_generator.dart';

void main() {
  final topics = [
    const Topic(
      id: 'dart',
      title: 'Основы Dart',
      minutes: 60,
      category: 'Основы',
    ),
    const Topic(
      id: 'widgets',
      title: 'Виджеты',
      minutes: 60,
      category: 'UI',
      prerequisites: ['dart'],
    ),
    const Topic(
      id: 'state',
      title: 'Состояние',
      minutes: 60,
      category: 'UI',
      prerequisites: ['widgets'],
    ),
  ];
  final r = const PlanGenerator().generate(
    topics: topics,
    settings: ScheduleSettings(
      hoursPerWeek: 7,
      studyDays: const {1, 2, 3, 4, 5, 6, 7},
      startDate: DateTime(2026, 10, 12),
      deadline: DateTime(2026, 10, 14),
    ),
  );
  for (final s in r.sessions) {
    print(
      '${s.date.day}.${s.date.month} ${s.kind.name} ${s.topicTitle} ${s.minutes} part ${s.part}/${s.totalParts}',
    );
  }
  print(
    'finish ${r.finishDate} met ${r.deadlineMet} required ${r.requiredHoursPerWeek}',
  );
}
