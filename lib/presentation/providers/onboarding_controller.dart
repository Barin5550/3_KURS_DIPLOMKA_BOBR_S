import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/direction.dart';
import '../../domain/entities/schedule_settings.dart';
import '../../domain/planner/dates.dart';
import '../../domain/planner/knowledge_estimator.dart';
import 'providers.dart';

/// Черновик нового плана, который заполняется на шагах онбординга.
class OnboardingDraft {
  const OnboardingDraft({
    this.direction,
    this.answers = const {},
    this.skippedTest = false,
    required this.settings,
  });

  final Direction? direction;

  /// Выбранный вариант ответа для каждой темы с вопросом (`-1` — «Не знаю»).
  final Map<String, int> answers;
  final bool skippedTest;
  final ScheduleSettings settings;

  /// Темы, которые пользователь знает по результатам теста.
  Set<String> get knownTopicIds {
    final d = direction;
    if (d == null || skippedTest) return const {};
    final correctness = <String, bool>{
      for (final t in d.diagnosticTopics)
        if (answers.containsKey(t.id))
          t.id: answers[t.id] == t.question!.answerIndex,
    };
    return const KnowledgeEstimator().knownTopics(d.topics, correctness);
  }

  OnboardingDraft copyWith({
    Direction? direction,
    Map<String, int>? answers,
    bool? skippedTest,
    ScheduleSettings? settings,
  }) => OnboardingDraft(
    direction: direction ?? this.direction,
    answers: answers ?? this.answers,
    skippedTest: skippedTest ?? this.skippedTest,
    settings: settings ?? this.settings,
  );
}

class OnboardingController extends Notifier<OnboardingDraft> {
  @override
  OnboardingDraft build() => OnboardingDraft(
    settings: ScheduleSettings(
      hoursPerWeek: 6,
      studyDays: const {1, 3, 5},
      startDate: ref.read(todayProvider),
    ),
  );

  void selectDirection(Direction direction) => state = OnboardingDraft(
    direction: direction,
    settings: state.settings.copyWith(startDate: ref.read(todayProvider)),
  );

  void answer(String topicId, int option) => state = state.copyWith(
    answers: {...state.answers, topicId: option},
    skippedTest: false,
  );

  void skipTest() => state = state.copyWith(answers: {}, skippedTest: true);

  void updateSettings(ScheduleSettings settings) =>
      state = state.copyWith(settings: settings);

  void reset() => ref.invalidateSelf();
}

final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
      OnboardingController.new,
    );

/// Дата по умолчанию для дедлайна — через 3 месяца.
DateTime defaultDeadline(DateTime today) => addDays(today, 90);
