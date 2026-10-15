// Планы обучения, темы плана и занятия через API.
// Слой: data. Реализует интерфейс PlanRepository запросами к серверу
// (адреса /api/plans/... и /api/sessions/...). Сам план составляет
// алгоритм в приложении (domain/planner), а сервер его сохраняет и отдаёт.
// Потоки watch... обновляются после каждого изменения данных (ApiClient.watch).

import '../../domain/entities/plan.dart';
import '../../domain/entities/schedule_settings.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/topic.dart';
import '../../domain/repositories/repositories.dart';
import 'api_client.dart';
import 'api_json.dart';

/// Репозиторий планов, работающий через сервер API.
class ApiPlanRepository implements PlanRepository {
  /// [api] — клиент, через который идут запросы.
  ApiPlanRepository(this._api);

  /// Клиент API.
  final ApiClient _api;

  /// Превращает ответ-список в список сущностей функцией [fromJson].
  List<T> _list<T>(Object? data, T Function(Json) fromJson) =>
      (data as List<dynamic>).cast<Json>().map(fromJson).toList();

  /// GET /api/plans — все планы пользователя.
  @override
  Stream<List<StudyPlan>> watchPlans(int userId) =>
      _api.watch(() async => _list(await _api.get('/api/plans'), planFromJson));

  /// GET /api/plans/active — активный план (или `null`).
  @override
  Stream<StudyPlan?> watchActivePlan(int userId) => _api.watch(() async {
    final data = await _api.get('/api/plans/active');
    return data == null ? null : planFromJson(data as Json);
  });

  /// GET /api/plans/{id} — план по id; `null`, если не найден.
  @override
  Future<StudyPlan?> planById(int planId) async {
    try {
      return planFromJson(await _api.get('/api/plans/$planId') as Json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/plans — сохраняет составленный план и возвращает его id.
  @override
  Future<int> createPlan({
    required int userId,
    required String directionId,
    required String title,
    required ScheduleSettings settings,
    required Set<String> knownTopicIds,
    required List<Topic> orderedTopics,
    required List<PlannedSession> sessions,
  }) async {
    final data = await _api.post('/api/plans', {
      'directionId': directionId,
      'title': title,
      'settings': settingsToJson(settings),
      'knownTopicIds': knownTopicIds.toList(),
      'orderedTopics': orderedTopics.map(topicToJson).toList(),
      'sessions': sessions.map(plannedSessionToJson).toList(),
    }) as Json;
    return data['id'] as int;
  }

  /// POST /api/plans/{id}/activate — делает план активным.
  @override
  Future<void> setActive(int userId, int planId) =>
      _api.post('/api/plans/$planId/activate');

  /// PATCH /api/plans/{id} — переименование.
  @override
  Future<void> renamePlan(int planId, String title) =>
      _api.patch('/api/plans/$planId', {'title': title});

  /// DELETE /api/plans/{id} — удаление плана.
  @override
  Future<void> deletePlan(int planId) => _api.delete('/api/plans/$planId');

  /// PUT /api/plans/{id}/settings — новые настройки расписания.
  @override
  Future<void> updateSettings(int planId, ScheduleSettings settings) =>
      _api.put('/api/plans/$planId/settings', settingsToJson(settings));

  /// GET /api/plans/{id}/topics — темы плана по порядку.
  @override
  Future<List<PlanTopic>> planTopics(int planId) async =>
      _list(await _api.get('/api/plans/$planId/topics'), planTopicFromJson);

  /// PUT /api/plans/{id}/topics — заменяет список тем плана.
  @override
  Future<void> replacePlanTopics(int planId, List<Topic> orderedTopics) =>
      _api.put('/api/plans/$planId/topics', {
        'topics': orderedTopics.map(topicToJson).toList(),
      });

  /// Поток занятий плана: GET /api/plans/{id}/sessions после каждого
  /// изменения данных.
  @override
  Stream<List<StudySession>> watchSessions(int planId) =>
      _api.watch(() => sessions(planId));

  /// GET /api/plans/{id}/sessions — занятия плана (однократно).
  @override
  Future<List<StudySession>> sessions(int planId) async => _list(
    await _api.get('/api/plans/$planId/sessions'),
    studySessionFromJson,
  );

  /// GET /api/sessions/{id} — одно занятие; `null`, если не найдено.
  @override
  Future<StudySession?> sessionById(int sessionId) async {
    try {
      final data = await _api.get('/api/sessions/$sessionId');
      return studySessionFromJson(data as Json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// PUT /api/sessions/{id}/done — отметка о выполнении.
  @override
  Future<void> setSessionDone(int sessionId, {required bool done}) =>
      _api.put('/api/sessions/$sessionId/done', {'done': done});

  /// PUT /api/plans/{id}/sessions/open — новое расписание невыполненных
  /// занятий (после перепланирования).
  @override
  Future<void> replaceOpenSessions(int planId, List<PlannedSession> sessions) =>
      _api.put('/api/plans/$planId/sessions/open', {
        'sessions': sessions.map(plannedSessionToJson).toList(),
      });

  /// GET /api/sessions/completed — выполненные занятия всех планов.
  @override
  Stream<List<StudySession>> watchCompletedSessions(int userId) => _api.watch(
    () async =>
        _list(await _api.get('/api/sessions/completed'), studySessionFromJson),
  );
}
