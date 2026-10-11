import 'package:drift/drift.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/repositories.dart';
import '../db/app_database.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Note>> watchNotes(int userId, {String? topicId}) {
    final query = _db.select(_db.notes)
      ..where((n) {
        final byUser = n.userId.equals(userId);
        return topicId == null ? byUser : byUser & n.topicId.equals(topicId);
      })
      ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]);
    return query.watch().map((rows) => rows.map(_toNote).toList());
  }

  @override
  Future<Note?> noteById(int id) async {
    final row = await (_db.select(
      _db.notes,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toNote(row);
  }

  @override
  Future<int> createNote({
    required int userId,
    required String title,
    required String body,
    String? topicId,
    String? topicTitle,
  }) {
    final now = DateTime.now();
    return _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            userId: userId,
            title: title.trim(),
            body: body.trim(),
            topicId: Value(topicId),
            topicTitle: Value(topicTitle),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  }) async {
    final updated = await (_db.update(_db.notes)..where((n) => n.id.equals(id)))
        .write(
          NotesCompanion(
            title: Value(title.trim()),
            body: Value(body.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
    if (updated == 0) throw const AppException('Заметка не найдена');
  }

  @override
  Future<void> deleteNote(int id) =>
      (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();

  Note _toNote(NoteRow r) => Note(
    id: r.id,
    userId: r.userId,
    title: r.title,
    body: r.body,
    topicId: r.topicId,
    topicTitle: r.topicTitle,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}

class PomodoroRepositoryImpl implements PomodoroRepository {
  PomodoroRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<void> logPomodoro({
    required int userId,
    required int minutes,
    String? topicTitle,
  }) => _db
      .into(_db.pomodoroLogs)
      .insert(
        PomodoroLogsCompanion.insert(
          userId: userId,
          minutes: minutes,
          topicTitle: Value(topicTitle),
          completedAt: DateTime.now(),
        ),
      );

  @override
  Stream<List<PomodoroEntry>> watchPomodoros(int userId) =>
      (_db.select(_db.pomodoroLogs)
            ..where((p) => p.userId.equals(userId))
            ..orderBy([(p) => OrderingTerm.desc(p.completedAt)]))
          .watch()
          .map(
            (rows) => rows
                .map(
                  (r) => PomodoroEntry(
                    id: r.id,
                    minutes: r.minutes,
                    completedAt: r.completedAt,
                    topicTitle: r.topicTitle,
                  ),
                )
                .toList(),
          );
}
