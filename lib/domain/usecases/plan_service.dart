// Сценарии (use cases) работы с планом (слой domain, папка usecases).
// Соединяет алгоритмы планировщика с хранилищем PlanRepository: создать
// план, отметить занятие, перепланировать, добавить или удалить тему.
// Создаётся в planServiceProvider (presentation/providers/providers.dart),
// вызывается с экранов предпросмотра, плана, главного, темы и настроек.

import '../entities/plan.dart';
import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import '../planner/dates.dart';
import '../planner/plan_generator.dart';
import '../planner/replanner.dart';
import '../planner/topological_sort.dart';
import '../repositories/repositories.dart';

/// Сценарии работы с планом: создание, отметка занятий, перепланирование.
///
/// Связывает чистые алгоритмы ([PlanGenerator], [Replanner]) с хранилищем
/// ([PlanRepository]). Время берётся из [clock], чтобы его можно было
/// подменить в тестах.
class PlanService {
  /// Первый параметр — репозиторий планов. [clock] — функция «который
  /// сейчас час» (если не передана — `DateTime.now`). [generator] и
  /// [replanner] по умолчанию стандартные, но их можно подменить.
  PlanService(
    this._plans, {
    DateTime Function()? clock,
    this.generator = const PlanGenerator(),
    this.replanner = const Replanner(),
  }) : _clock = clock ?? DateTime.now;

  /// Хранилище планов, тем плана и занятий (реализация — в слое data).
  final PlanRepository _plans;

  /// Функция, которая возвращает текущие дату и время.
  final DateTime Function() _clock;

  /// Алгоритм построения нового плана.
  final PlanGenerator generator;

  /// Алгоритм перестройки существующего плана.
  final Replanner replanner;

  /// Сегодняшняя дата без времени суток (берётся из [_clock]).
  DateTime get today => dateOnly(_clock());

  /// Рассчитывает план без сохранения (экран предпросмотра).
  PlanResult preview({
    required List<Topic> topics,
    required ScheduleSettings settings,
    required Set<String> knownTopicIds,
  }) => generator.generate(
    topics: topics,
    settings: settings,
    knownTopicIds: knownTopicIds,
  );

  /// Генерирует и сохраняет план; новый план становится активным.
  /// Возвращает id сохранённого плана.
  Future<int> createPlan({
    required int userId,
    required String directionId,
    required String title,
    required List<Topic> topics,
    required ScheduleSettings settings,
    required Set<String> knownTopicIds,
  }) {
    // Сначала рассчитываем план теми же алгоритмами, что и в предпросмотре.
    final result = preview(
      topics: topics,
      settings: settings,
      knownTopicIds: knownTopicIds,
    );
    // Сохраняем в базу план, его темы в порядке изучения и все занятия.
    return _plans.createPlan(
      userId: userId,
      directionId: directionId,
      title: title,
      settings: settings,
      knownTopicIds: knownTopicIds,
      orderedTopics: result.orderedTopics,
      sessions: result.sessions,
    );
  }

  /// Переключает отметку занятия: невыполненное становится выполненным,
  /// а выполненное — снова невыполненным.
  Future<void> toggleSession(StudySession session) =>
      _plans.setSessionDone(session.id, done: !session.isDone);

  /// Перестраивает невыполненную часть плана начиная с сегодняшнего дня.
  ///
  /// [settings] — новые настройки расписания; если не переданы, берутся
  /// сохранённые настройки плана.
  Future<ReplanResult> replan(
    StudyPlan plan, {
    ScheduleSettings? settings,
  }) async {
    // Загружаем из базы темы плана и все его занятия.
    final topics = await _plans.planTopics(plan.id);
    final sessions = await _plans.sessions(plan.id);
    // Запускаем алгоритм перепланирования.
    final result = replanner.replan(
      // Темы плана (снимки из базы) переводим в объекты Topic.
      orderedTopics: topics.map((t) => t.toTopic()).toList(),
      sessions: sessions,
      // Новые настройки, если переданы, иначе — настройки плана.
      settings: settings ?? plan.settings,
      today: today,
    );
    // Заменяем в базе невыполненные занятия новыми; выполненные остаются.
    await _plans.replaceOpenSessions(plan.id, result.sessions);
    // Возвращаем результат (дата окончания, успеваем ли к дедлайну).
    return result;
  }

  /// Меняет расписание плана и сразу перестраивает его.
  Future<ReplanResult> updateSettings(
    StudyPlan plan,
    ScheduleSettings settings,
  ) async {
    // Сохраняем новые настройки расписания в базе.
    await _plans.updateSettings(plan.id, settings);
    // Перестраиваем план. settings передаём явно: в объекте plan ещё
    // лежат старые настройки.
    return replan(plan, settings: settings);
  }

  /// Добавляет тему (например, собственную) в план: темы плана заново
  /// упорядочиваются алгоритмом Кана, затем план перестраивается.
  Future<ReplanResult> addTopic(StudyPlan plan, Topic topic) async {
    // Текущие темы плана из базы.
    final current = await _plans.planTopics(plan.id);
    // Одну и ту же тему дважды добавить нельзя — показываем ошибку.
    if (current.any((t) => t.topicId == topic.id)) {
      throw const AppException('Эта тема уже есть в плане');
    }
    // Заново упорядочиваем все темы плана вместе с новой, чтобы новая
    // тема встала после своих зависимостей.
    final ordered = topologicalSort([
      ...current.map((t) => t.toTopic()),
      topic,
    ]);
    // Сохраняем новый список тем плана.
    await _plans.replacePlanTopics(plan.id, ordered);
    // Перестраиваем занятия с учётом новой темы.
    return replan(plan);
  }

  /// Удаляет тему из плана вместе с её невыполненными занятиями.
  Future<ReplanResult> removeTopic(StudyPlan plan, String topicId) async {
    // Текущие темы плана из базы.
    final current = await _plans.planTopics(plan.id);
    // Все темы, кроме удаляемой, в виде объектов Topic.
    final rest = current.where((t) => t.topicId != topicId).map((t) {
      return t.toTopic();
    }).toList();
    // Сохраняем укороченный список тем.
    await _plans.replacePlanTopics(plan.id, rest);
    // Перепланируем: невыполненные занятия заменятся новыми, в которых
    // удалённой темы уже нет.
    return replan(plan);
  }
}
