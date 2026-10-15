// Состояние мастера создания плана — онбординга (слой presentation).
// Хранит черновик: выбранное направление, ответы диагностического теста и
// параметры расписания. Его заполняют экраны screens/onboarding/ (выбор
// направления, тест, расписание), а экран предпросмотра создаёт по нему план.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/direction.dart';
import '../../domain/entities/schedule_settings.dart';
import '../../domain/planner/dates.dart';
import '../../domain/planner/knowledge_estimator.dart';
import 'providers.dart';

/// Черновик нового плана, который заполняется на шагах онбординга.
///
/// Объект неизменяемый: при каждом изменении создаётся новая копия
/// через [copyWith], и экраны перерисовываются.
class OnboardingDraft {
  /// Пустой черновик: направление не выбрано, ответов нет.
  /// Параметры расписания [settings] обязательны.
  const OnboardingDraft({
    this.direction,
    this.answers = const {},
    this.skippedTest = false,
    required this.settings,
  });

  /// Выбранное направление обучения (`null`, пока не выбрано).
  final Direction? direction;

  /// Выбранный вариант ответа для каждой темы с вопросом (`-1` — «Не знаю»).
  final Map<String, int> answers;

  /// `true`, если пользователь пропустил диагностический тест.
  final bool skippedTest;

  /// Часы в неделю, учебные дни, дата начала и дедлайн.
  final ScheduleSettings settings;

  /// Темы, которые пользователь знает по результатам теста.
  Set<String> get knownTopicIds {
    // Локальная копия поля, чтобы Dart понял, что дальше она не null.
    final d = direction;
    // Без направления или при пропущенном тесте знаний нет.
    if (d == null || skippedTest) return const {};
    // Для каждой темы, на вопрос которой дан ответ, отмечаем:
    // верный ответ (true) или нет (false).
    final correctness = <String, bool>{
      for (final t in d.diagnosticTopics)
        if (answers.containsKey(t.id))
          t.id: answers[t.id] == t.question!.answerIndex,
    };
    // KnowledgeEstimator по графу тем определяет, какие темы уже известны
    // (верный ответ по теме засчитывает и все темы, нужные до неё).
    return const KnowledgeEstimator().knownTopics(d.topics, correctness);
  }

  /// Копия черновика, в которой заменены только переданные поля.
  OnboardingDraft copyWith({
    Direction? direction,
    Map<String, int>? answers,
    bool? skippedTest,
    ScheduleSettings? settings,
  }) => OnboardingDraft(
    // Если новое значение не передано (null), берём старое.
    direction: direction ?? this.direction,
    answers: answers ?? this.answers,
    skippedTest: skippedTest ?? this.skippedTest,
    settings: settings ?? this.settings,
  );
}

/// Контроллер онбординга: меняет черновик по действиям пользователя.
///
/// Riverpod — библиотека управления состоянием. Notifier — класс, который
/// хранит значение (`state`) и уведомляет экраны, когда оно меняется.
class OnboardingController extends Notifier<OnboardingDraft> {
  /// Начальный черновик: 6 часов в неделю, занятия в пн, ср и пт,
  /// начало — сегодня.
  @override
  OnboardingDraft build() => OnboardingDraft(
    settings: ScheduleSettings(
      hoursPerWeek: 6,
      // 1 — понедельник, 3 — среда, 5 — пятница.
      studyDays: const {1, 3, 5},
      // Сегодняшняя дата берётся из провайдера (в тестах её подменяют).
      startDate: ref.read(todayProvider),
    ),
  );

  /// Выбор направления. Черновик начинается заново: прежние ответы теста
  /// сбрасываются, расписание сохраняется, а дата начала — сегодня.
  void selectDirection(Direction direction) => state = OnboardingDraft(
    direction: direction,
    settings: state.settings.copyWith(startDate: ref.read(todayProvider)),
  );

  /// Запоминает ответ [option] на вопрос темы [topicId].
  /// Если тест был пропущен, отметка пропуска снимается.
  void answer(String topicId, int option) => state = state.copyWith(
    // Новый словарь: старые ответы плюс этот (прежний ответ заменяется).
    answers: {...state.answers, topicId: option},
    skippedTest: false,
  );

  /// Пропуск теста: ответы стираются, и ни одна тема не будет считаться
  /// уже изученной (см. [OnboardingDraft.knownTopicIds]).
  void skipTest() => state = state.copyWith(answers: {}, skippedTest: true);

  /// Сохраняет параметры расписания с экрана настройки расписания.
  void updateSettings(ScheduleSettings settings) =>
      state = state.copyWith(settings: settings);

  /// Сбрасывает черновик к начальному (после создания плана):
  /// invalidateSelf заставляет Riverpod заново вызвать [build].
  void reset() => ref.invalidateSelf();
}

/// Провайдер черновика онбординга. Экраны читают черновик через
/// `ref.watch(onboardingProvider)`, а меняют через
/// `ref.read(onboardingProvider.notifier)`.
final onboardingProvider =
    NotifierProvider<OnboardingController, OnboardingDraft>(
      OnboardingController.new,
    );

/// Дата по умолчанию для дедлайна — через 3 месяца.
/// (Используется экраном расписания, когда пользователь включает дедлайн.)
DateTime defaultDeadline(DateTime today) => addDays(today, 90);
