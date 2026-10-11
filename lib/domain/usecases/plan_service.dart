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
  PlanService(
    this._plans, {
    DateTime Function()? clock,
    this.generator = const PlanGenerator(),
    this.replanner = const Replanner(),
  }) : _clock = clock ?? DateTime.now;

  final PlanRepository _plans;
  final DateTime Function() _clock;
  final PlanGenerator generator;
  final Replanner replanner;

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
  Future<int> createPlan({
    required int userId,
    required String directionId,
    required String title,
    required List<Topic> topics,
    required ScheduleSettings settings,
    required Set<String> knownTopicIds,
  }) {
    final result = preview(
      topics: topics,
      settings: settings,
      knownTopicIds: knownTopicIds,
    );
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

  Future<void> toggleSession(StudySession session) =>
      _plans.setSessionDone(session.id, done: !session.isDone);

  /// Перестраивает невыполненную часть плана начиная с сегодняшнего дня.
  Future<ReplanResult> replan(
    StudyPlan plan, {
    ScheduleSettings? settings,
  }) async {
    final topics = await _plans.planTopics(plan.id);
    final sessions = await _plans.sessions(plan.id);
    final result = replanner.replan(
      orderedTopics: topics.map((t) => t.toTopic()).toList(),
      sessions: sessions,
      settings: settings ?? plan.settings,
      today: today,
    );
    await _plans.replaceOpenSessions(plan.id, result.sessions);
    return result;
  }

  /// Меняет расписание плана и сразу перестраивает его.
  Future<ReplanResult> updateSettings(
    StudyPlan plan,
    ScheduleSettings settings,
  ) async {
    await _plans.updateSettings(plan.id, settings);
    return replan(plan, settings: settings);
  }

  /// Добавляет тему (например, собственную) в план: темы плана заново
  /// упорядочиваются алгоритмом Кана, затем план перестраивается.
  Future<ReplanResult> addTopic(StudyPlan plan, Topic topic) async {
    final current = await _plans.planTopics(plan.id);
    if (current.any((t) => t.topicId == topic.id)) {
      throw const AppException('Эта тема уже есть в плане');
    }
    final ordered = topologicalSort([
      ...current.map((t) => t.toTopic()),
      topic,
    ]);
    await _plans.replacePlanTopics(plan.id, ordered);
    return replan(plan);
  }

  /// Удаляет тему из плана вместе с её невыполненными занятиями.
  Future<ReplanResult> removeTopic(StudyPlan plan, String topicId) async {
    final current = await _plans.planTopics(plan.id);
    final rest = current.where((t) => t.topicId != topicId).map((t) {
      return t.toTopic();
    }).toList();
    await _plans.replacePlanTopics(plan.id, rest);
    return replan(plan);
  }
}
