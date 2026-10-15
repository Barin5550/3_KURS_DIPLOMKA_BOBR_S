// Репозиторий учебных планов (слой data).
// Реализует интерфейс PlanRepository из слоя domain: сохраняет планы, темы
// плана и занятия в таблицах plans, plan_topics и sessions базы SQLite
// (через drift). Используется сервером API (lib/server/api_server.dart);
// приложение работает с планами через lib/data/api/api_plan_repository.dart.

import 'package:drift/drift.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/schedule_settings.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/topic.dart';
import '../../domain/repositories/repositories.dart';
import '../db/app_database.dart';

/// Хранение планов, их тем и занятий в SQLite.
///
/// drift — библиотека для работы с SQLite: запросы пишутся на Dart,
/// а методы `watch...` возвращают поток (Stream), который сам присылает
/// новые данные при каждом изменении таблицы.
class PlanRepositoryImpl implements PlanRepository {
  /// Получает объект базы данных, общий для всего приложения.
  PlanRepositoryImpl(this._db);

  /// База данных приложения (таблицы описаны в data/db/app_database.dart).
  final AppDatabase _db;

  // ---------------------------------------------------------------- планы

  /// Поток всех планов пользователя, новые сверху.
  @override
  Stream<List<StudyPlan>> watchPlans(int userId) {
    // SELECT из plans для этого пользователя, по дате создания по убыванию.
    final query = _db.select(_db.plans)
      ..where((p) => p.userId.equals(userId))
      ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]);
    // Каждую строку превращаем в сущность StudyPlan.
    return query.watch().map((rows) => rows.map(_toPlan).toList());
  }

  /// Поток активного плана пользователя (или `null`, если планов нет).
  @override
  Stream<StudyPlan?> watchActivePlan(int userId) {
    // Ищем план этого пользователя с отметкой isActive, максимум одну строку.
    final query = _db.select(_db.plans)
      ..where((p) => p.userId.equals(userId) & p.isActive.equals(true))
      ..limit(1);
    // Следим за одной строкой; отсутствие строки превращается в null.
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toPlan(row),
    );
  }

  /// План по id или `null`, если его нет.
  @override
  Future<StudyPlan?> planById(int planId) async {
    // SELECT * FROM plans WHERE id = ?.
    final row = await (_db.select(
      _db.plans,
    )..where((p) => p.id.equals(planId))).getSingleOrNull();
    return row == null ? null : _toPlan(row);
  }

  /// Сохраняет новый план вместе с темами и занятиями и делает его
  /// активным. Возвращает id нового плана.
  ///
  /// [orderedTopics] — темы в порядке изучения, [sessions] — занятия,
  /// которые рассчитал генератор расписания.
  @override
  Future<int> createPlan({
    required int userId,
    required String directionId,
    required String title,
    required ScheduleSettings settings,
    required Set<String> knownTopicIds,
    required List<Topic> orderedTopics,
    required List<PlannedSession> sessions,
  }) {
    // Транзакция: либо сохраняется весь план, либо ничего.
    return _db.transaction(() async {
      // Активным может быть только один план: снимаем отметку со всех
      // остальных планов пользователя.
      await (_db.update(_db.plans)..where((p) => p.userId.equals(userId)))
          .write(const PlansCompanion(isActive: Value(false)));

      // Вставляем сам план и получаем его id.
      final planId = await _db
          .into(_db.plans)
          .insert(
            PlansCompanion.insert(
              userId: userId,
              directionId: directionId,
              title: title,
              hoursPerWeek: settings.hoursPerWeek,
              // Дни недели хранятся строкой «1,3,5».
              studyDays: _encodeDays(settings.studyDays),
              startDate: settings.startDate,
              deadline: Value(settings.deadline),
              // Темы, которые пользователь уже знает, — тоже через запятую.
              knownTopicIds: Value(knownTopicIds.join(',')),
              // Новый план сразу становится активным.
              isActive: const Value(true),
              createdAt: DateTime.now(),
            ),
          );
      // Сохраняем темы плана и занятия, привязанные к его id.
      await _insertPlanTopics(planId, orderedTopics);
      await _insertSessions(planId, sessions);
      return planId;
    });
  }

  /// Делает план [planId] активным, а остальные планы пользователя —
  /// неактивными (в одной транзакции).
  @override
  Future<void> setActive(int userId, int planId) => _db.transaction(() async {
    // Сначала снимаем отметку активности со всех планов пользователя.
    await (_db.update(_db.plans)..where((p) => p.userId.equals(userId))).write(
      const PlansCompanion(isActive: Value(false)),
    );
    // Затем ставим её выбранному плану.
    await (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
      const PlansCompanion(isActive: Value(true)),
    );
  });

  /// Переименовывает план (лишние пробелы по краям обрезаются).
  @override
  Future<void> renamePlan(int planId, String title) =>
      (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
        PlansCompanion(title: Value(title.trim())),
      );

  /// Удаляет план. Если он был активным, активным становится самый новый
  /// из оставшихся планов пользователя.
  @override
  Future<void> deletePlan(int planId) => _db.transaction(() async {
    // Запоминаем план до удаления: нужно знать, был ли он активным.
    final plan = await planById(planId);
    // Темы и занятия удаляются каскадно (FOREIGN KEY … ON DELETE CASCADE).
    await (_db.delete(_db.plans)..where((p) => p.id.equals(planId))).go();
    if (plan != null && plan.isActive) {
      // Делаем активным самый новый из оставшихся планов.
      final next =
          await (_db.select(_db.plans)
                ..where((p) => p.userId.equals(plan.userId))
                ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
                ..limit(1))
              .getSingleOrNull();
      // Если планы ещё остались — отмечаем найденный как активный.
      if (next != null) {
        await (_db.update(_db.plans)..where((p) => p.id.equals(next.id))).write(
          const PlansCompanion(isActive: Value(true)),
        );
      }
    }
  });

  /// Сохраняет новые параметры расписания плана: часы в неделю, учебные
  /// дни и дедлайн. Дата начала здесь не меняется.
  @override
  Future<void> updateSettings(int planId, ScheduleSettings settings) =>
      (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
        PlansCompanion(
          hoursPerWeek: Value(settings.hoursPerWeek),
          studyDays: Value(_encodeDays(settings.studyDays)),
          deadline: Value(settings.deadline),
        ),
      );

  // ----------------------------------------------------------- темы плана

  /// Темы плана в порядке изучения.
  @override
  Future<List<PlanTopic>> planTopics(int planId) async {
    // SELECT из plan_topics для плана, сортировка по позиции в очереди.
    final rows =
        await (_db.select(_db.planTopics)
              ..where((t) => t.planId.equals(planId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    // Каждую строку переводим в сущность PlanTopic.
    return rows
        .map(
          (r) => PlanTopic(
            topicId: r.topicId,
            title: r.title,
            category: r.category,
            minutes: r.minutes,
            level: r.level,
            // Строку «a,b,c» превращаем обратно в список id.
            prerequisites: _split(r.prerequisites),
            position: r.position,
          ),
        )
        .toList();
  }

  /// Полностью заменяет список тем плана новым (старые темы удаляются).
  @override
  Future<void> replacePlanTopics(int planId, List<Topic> orderedTopics) =>
      _db.transaction(() async {
        // Удаляем все темы плана...
        await (_db.delete(
          _db.planTopics,
        )..where((t) => t.planId.equals(planId))).go();
        // ...и вставляем новый список в нужном порядке.
        await _insertPlanTopics(planId, orderedTopics);
      });

  // -------------------------------------------------------------- занятия

  /// Поток занятий плана, отсортированных по дате.
  @override
  Stream<List<StudySession>> watchSessions(int planId) =>
      _sessionsQuery(planId).watch().map((r) => r.map(_toSession).toList());

  /// Занятия плана (однократное чтение, без потока).
  @override
  Future<List<StudySession>> sessions(int planId) async =>
      (await _sessionsQuery(planId).get()).map(_toSession).toList();

  /// Занятие по id или `null`, если его нет.
  @override
  Future<StudySession?> sessionById(int sessionId) async {
    // SELECT * FROM sessions WHERE id = ?.
    final row = await (_db.select(
      _db.sessions,
    )..where((s) => s.id.equals(sessionId))).getSingleOrNull();
    return row == null ? null : _toSession(row);
  }

  /// Отмечает занятие выполненным ([done] = `true`) или снимает отметку.
  @override
  Future<void> setSessionDone(int sessionId, {required bool done}) =>
      (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId))).write(
        SessionsCompanion(
          isDone: Value(done),
          // Время выполнения запоминается; при снятии отметки стирается.
          completedAt: Value(done ? DateTime.now() : null),
        ),
      );

  /// Удаляет невыполненные занятия плана и сохраняет новые
  /// (перепланирование). Выполненные занятия остаются для истории.
  @override
  Future<void> replaceOpenSessions(int planId, List<PlannedSession> sessions) =>
      _db.transaction(() async {
        // Удаляем только занятия этого плана, у которых isDone = false.
        await (_db.delete(
          _db.sessions,
        )..where((s) => s.planId.equals(planId) & s.isDone.equals(false))).go();
        // Сохраняем новое расписание.
        await _insertSessions(planId, sessions);
      });

  /// Поток всех выполненных занятий пользователя по всем его планам,
  /// последние сверху (для статистики и истории).
  @override
  Stream<List<StudySession>> watchCompletedSessions(int userId) {
    // В таблице sessions нет id пользователя, поэтому соединяем её
    // с таблицей plans (JOIN) и фильтруем по владельцу плана.
    final query =
        _db.select(_db.sessions).join([
            innerJoin(_db.plans, _db.plans.id.equalsExp(_db.sessions.planId)),
          ])
          // Только планы этого пользователя и только выполненные занятия.
          ..where(
            _db.plans.userId.equals(userId) & _db.sessions.isDone.equals(true),
          )
          // Сначала занятия, выполненные позже всех.
          ..orderBy([OrderingTerm.desc(_db.sessions.completedAt)]);
    // Из каждой строки результата берём часть, относящуюся к sessions.
    return query.watch().map(
      (rows) => rows.map((r) => _toSession(r.readTable(_db.sessions))).toList(),
    );
  }

  // --------------------------------------------------------- служебное

  /// Общий запрос занятий плана: по дате, при равной дате — по id.
  /// Используется в [watchSessions] и [sessions].
  SimpleSelectStatement<$SessionsTable, SessionRow> _sessionsQuery(
    int planId,
  ) => _db.select(_db.sessions)
    ..where((s) => s.planId.equals(planId))
    ..orderBy([(s) => OrderingTerm.asc(s.date), (s) => OrderingTerm.asc(s.id)]);

  /// Сохраняет темы плана одной пачкой (batch — несколько INSERT за раз).
  /// Номер темы в списке записывается в поле position — это порядок изучения.
  Future<void> _insertPlanTopics(int planId, List<Topic> topics) =>
      _db.batch((b) {
        b.insertAll(_db.planTopics, [
          // Для каждой темы создаём строку; i — её место в очереди.
          for (var i = 0; i < topics.length; i++)
            PlanTopicsCompanion.insert(
              planId: planId,
              topicId: topics[i].id,
              title: topics[i].title,
              category: topics[i].category,
              minutes: topics[i].minutes,
              level: topics[i].level,
              prerequisites: Value(topics[i].prerequisites.join(',')),
              position: i,
            ),
        ]);
      });

  /// Сохраняет рассчитанные занятия плана одной пачкой.
  Future<void> _insertSessions(int planId, List<PlannedSession> sessions) =>
      _db.batch((b) {
        b.insertAll(_db.sessions, [
          // Каждое запланированное занятие превращаем в строку таблицы.
          for (final s in sessions)
            SessionsCompanion.insert(
              planId: planId,
              topicId: s.topicId,
              topicTitle: s.topicTitle,
              category: s.category,
              date: s.date,
              minutes: s.minutes,
              // Тип занятия (изучение или повторение) хранится его именем.
              kind: s.kind.name,
              // Номер части темы и общее число частей.
              part: Value(s.part),
              totalParts: Value(s.totalParts),
            ),
        ]);
      });

  /// Кодирует набор дней недели в строку: {5, 1, 3} → «1,3,5».
  static String _encodeDays(Set<int> days) => (days.toList()..sort()).join(',');

  /// Разбивает строку «a,b,c» в список; пустая строка — пустой список.
  static List<String> _split(String value) =>
      value.isEmpty ? const [] : value.split(',');

  /// Переводит строку таблицы [PlanRow] в сущность [StudyPlan].
  StudyPlan _toPlan(PlanRow r) => StudyPlan(
    id: r.id,
    userId: r.userId,
    directionId: r.directionId,
    title: r.title,
    // Параметры расписания собираются обратно в объект ScheduleSettings.
    settings: ScheduleSettings(
      hoursPerWeek: r.hoursPerWeek,
      // «1,3,5» → {1, 3, 5}.
      studyDays: _split(r.studyDays).map(int.parse).toSet(),
      startDate: r.startDate,
      deadline: r.deadline,
    ),
    knownTopicIds: _split(r.knownTopicIds).toSet(),
    isActive: r.isActive,
    createdAt: r.createdAt,
  );

  /// Переводит строку таблицы [SessionRow] в сущность [StudySession].
  StudySession _toSession(SessionRow r) => StudySession(
    id: r.id,
    planId: r.planId,
    topicId: r.topicId,
    topicTitle: r.topicTitle,
    category: r.category,
    date: r.date,
    minutes: r.minutes,
    // Имя типа из базы превращаем обратно в значение enum SessionKind.
    kind: SessionKind.fromName(r.kind),
    part: r.part,
    totalParts: r.totalParts,
    isDone: r.isDone,
    completedAt: r.completedAt,
  );
}
