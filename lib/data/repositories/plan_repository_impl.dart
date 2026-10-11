import 'package:drift/drift.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/schedule_settings.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/topic.dart';
import '../../domain/repositories/repositories.dart';
import '../db/app_database.dart';

/// Хранение планов, их тем и занятий в SQLite.
class PlanRepositoryImpl implements PlanRepository {
  PlanRepositoryImpl(this._db);

  final AppDatabase _db;

  // ---------------------------------------------------------------- планы

  @override
  Stream<List<StudyPlan>> watchPlans(int userId) {
    final query = _db.select(_db.plans)
      ..where((p) => p.userId.equals(userId))
      ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]);
    return query.watch().map((rows) => rows.map(_toPlan).toList());
  }

  @override
  Stream<StudyPlan?> watchActivePlan(int userId) {
    final query = _db.select(_db.plans)
      ..where((p) => p.userId.equals(userId) & p.isActive.equals(true))
      ..limit(1);
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _toPlan(row),
    );
  }

  @override
  Future<StudyPlan?> planById(int planId) async {
    final row = await (_db.select(
      _db.plans,
    )..where((p) => p.id.equals(planId))).getSingleOrNull();
    return row == null ? null : _toPlan(row);
  }

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
      await (_db.update(_db.plans)..where((p) => p.userId.equals(userId)))
          .write(const PlansCompanion(isActive: Value(false)));

      final planId = await _db
          .into(_db.plans)
          .insert(
            PlansCompanion.insert(
              userId: userId,
              directionId: directionId,
              title: title,
              hoursPerWeek: settings.hoursPerWeek,
              studyDays: _encodeDays(settings.studyDays),
              startDate: settings.startDate,
              deadline: Value(settings.deadline),
              knownTopicIds: Value(knownTopicIds.join(',')),
              isActive: const Value(true),
              createdAt: DateTime.now(),
            ),
          );
      await _insertPlanTopics(planId, orderedTopics);
      await _insertSessions(planId, sessions);
      return planId;
    });
  }

  @override
  Future<void> setActive(int userId, int planId) => _db.transaction(() async {
    await (_db.update(_db.plans)..where((p) => p.userId.equals(userId))).write(
      const PlansCompanion(isActive: Value(false)),
    );
    await (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
      const PlansCompanion(isActive: Value(true)),
    );
  });

  @override
  Future<void> renamePlan(int planId, String title) =>
      (_db.update(_db.plans)..where((p) => p.id.equals(planId))).write(
        PlansCompanion(title: Value(title.trim())),
      );

  @override
  Future<void> deletePlan(int planId) => _db.transaction(() async {
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
      if (next != null) {
        await (_db.update(_db.plans)..where((p) => p.id.equals(next.id))).write(
          const PlansCompanion(isActive: Value(true)),
        );
      }
    }
  });

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

  @override
  Future<List<PlanTopic>> planTopics(int planId) async {
    final rows =
        await (_db.select(_db.planTopics)
              ..where((t) => t.planId.equals(planId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return rows
        .map(
          (r) => PlanTopic(
            topicId: r.topicId,
            title: r.title,
            category: r.category,
            minutes: r.minutes,
            level: r.level,
            prerequisites: _split(r.prerequisites),
            position: r.position,
          ),
        )
        .toList();
  }

  @override
  Future<void> replacePlanTopics(int planId, List<Topic> orderedTopics) =>
      _db.transaction(() async {
        await (_db.delete(
          _db.planTopics,
        )..where((t) => t.planId.equals(planId))).go();
        await _insertPlanTopics(planId, orderedTopics);
      });

  // -------------------------------------------------------------- занятия

  @override
  Stream<List<StudySession>> watchSessions(int planId) =>
      _sessionsQuery(planId).watch().map((r) => r.map(_toSession).toList());

  @override
  Future<List<StudySession>> sessions(int planId) async =>
      (await _sessionsQuery(planId).get()).map(_toSession).toList();

  @override
  Future<StudySession?> sessionById(int sessionId) async {
    final row = await (_db.select(
      _db.sessions,
    )..where((s) => s.id.equals(sessionId))).getSingleOrNull();
    return row == null ? null : _toSession(row);
  }

  @override
  Future<void> setSessionDone(int sessionId, {required bool done}) =>
      (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId))).write(
        SessionsCompanion(
          isDone: Value(done),
          completedAt: Value(done ? DateTime.now() : null),
        ),
      );

  @override
  Future<void> replaceOpenSessions(
    int planId,
    List<PlannedSession> sessions,
  ) => _db.transaction(() async {
    await (_db.delete(
      _db.sessions,
    )..where((s) => s.planId.equals(planId) & s.isDone.equals(false))).go();
    await _insertSessions(planId, sessions);
  });

  @override
  Stream<List<StudySession>> watchCompletedSessions(int userId) {
    final query =
        _db.select(_db.sessions).join([
            innerJoin(_db.plans, _db.plans.id.equalsExp(_db.sessions.planId)),
          ])
          ..where(
            _db.plans.userId.equals(userId) & _db.sessions.isDone.equals(true),
          )
          ..orderBy([OrderingTerm.desc(_db.sessions.completedAt)]);
    return query.watch().map(
      (rows) => rows.map((r) => _toSession(r.readTable(_db.sessions))).toList(),
    );
  }

  // --------------------------------------------------------- служебное

  SimpleSelectStatement<$SessionsTable, SessionRow> _sessionsQuery(
    int planId,
  ) => _db.select(_db.sessions)
    ..where((s) => s.planId.equals(planId))
    ..orderBy([(s) => OrderingTerm.asc(s.date), (s) => OrderingTerm.asc(s.id)]);

  Future<void> _insertPlanTopics(int planId, List<Topic> topics) =>
      _db.batch((b) {
        b.insertAll(_db.planTopics, [
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

  Future<void> _insertSessions(int planId, List<PlannedSession> sessions) =>
      _db.batch((b) {
        b.insertAll(_db.sessions, [
          for (final s in sessions)
            SessionsCompanion.insert(
              planId: planId,
              topicId: s.topicId,
              topicTitle: s.topicTitle,
              category: s.category,
              date: s.date,
              minutes: s.minutes,
              kind: s.kind.name,
              part: Value(s.part),
              totalParts: Value(s.totalParts),
            ),
        ]);
      });

  static String _encodeDays(Set<int> days) => (days.toList()..sort()).join(',');

  static List<String> _split(String value) =>
      value.isEmpty ? const [] : value.split(',');

  StudyPlan _toPlan(PlanRow r) => StudyPlan(
    id: r.id,
    userId: r.userId,
    directionId: r.directionId,
    title: r.title,
    settings: ScheduleSettings(
      hoursPerWeek: r.hoursPerWeek,
      studyDays: _split(r.studyDays).map(int.parse).toSet(),
      startDate: r.startDate,
      deadline: r.deadline,
    ),
    knownTopicIds: _split(r.knownTopicIds).toSet(),
    isActive: r.isActive,
    createdAt: r.createdAt,
  );

  StudySession _toSession(SessionRow r) => StudySession(
    id: r.id,
    planId: r.planId,
    topicId: r.topicId,
    topicTitle: r.topicTitle,
    category: r.category,
    date: r.date,
    minutes: r.minutes,
    kind: SessionKind.fromName(r.kind),
    part: r.part,
    totalParts: r.totalParts,
    isDone: r.isDone,
    completedAt: r.completedAt,
  );
}
