// Репозитории заметок и «помидоров» (слой data).
// Реализуют интерфейсы NoteRepository и PomodoroRepository из слоя domain
// и хранят данные в локальной базе SQLite через библиотеку drift.
// Создаются в noteRepositoryProvider и pomodoroRepositoryProvider
// (presentation/providers/providers.dart), используются экранами заметок
// и таймера Pomodoro.

import 'package:drift/drift.dart';

import '../../domain/entities/note.dart';
import '../../domain/repositories/repositories.dart';
import '../db/app_database.dart';

/// Заметки пользователя в таблице `notes`.
///
/// drift — библиотека для работы с SQLite: запросы пишутся на Dart,
/// а drift превращает их в SQL и умеет следить за изменениями таблиц.
class NoteRepositoryImpl implements NoteRepository {
  /// Получает объект базы данных, общий для всего приложения.
  NoteRepositoryImpl(this._db);

  /// База данных приложения (таблицы описаны в data/db/app_database.dart).
  final AppDatabase _db;

  /// Поток заметок пользователя, самые свежие сверху.
  ///
  /// Если передан [topicId], возвращаются только заметки по этой теме.
  /// Поток (Stream) сам присылает новый список при любом изменении таблицы.
  @override
  Stream<List<Note>> watchNotes(int userId, {String? topicId}) {
    // Запрос SELECT к таблице notes.
    final query = _db.select(_db.notes)
      // Условие WHERE: только заметки этого пользователя...
      ..where((n) {
        final byUser = n.userId.equals(userId);
        // ...и, если тема указана, только по этой теме.
        return topicId == null ? byUser : byUser & n.topicId.equals(topicId);
      })
      // Сортировка по дате изменения: новые заметки первыми.
      ..orderBy([(n) => OrderingTerm.desc(n.updatedAt)]);
    // watch() следит за таблицей; каждую строку переводим в сущность Note.
    return query.watch().map((rows) => rows.map(_toNote).toList());
  }

  /// Одна заметка по id или `null`, если такой нет.
  @override
  Future<Note?> noteById(int id) async {
    // Ищем строку с нужным id (не больше одной).
    final row = await (_db.select(
      _db.notes,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
    // Строку базы превращаем в сущность domain.
    return row == null ? null : _toNote(row);
  }

  /// Создаёт заметку и возвращает её id.
  ///
  /// [topicId] и [topicTitle] заполняются, если заметка привязана к теме.
  @override
  Future<int> createNote({
    required int userId,
    required String title,
    required String body,
    String? topicId,
    String? topicTitle,
  }) {
    // Одно и то же время для даты создания и даты изменения.
    final now = DateTime.now();
    // INSERT в таблицу notes; drift вернёт id новой строки.
    return _db
        .into(_db.notes)
        .insert(
          // Companion — набор значений для вставки. Лишние пробелы по краям
          // заголовка и текста обрезаются.
          NotesCompanion.insert(
            userId: userId,
            title: title.trim(),
            body: body.trim(),
            // Value(...) — необязательные поля, они могут быть null.
            topicId: Value(topicId),
            topicTitle: Value(topicTitle),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  /// Меняет заголовок и текст заметки и обновляет дату изменения.
  ///
  /// Бросает [AppException], если заметки с таким id нет.
  @override
  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  }) async {
    // UPDATE notes ... WHERE id = ?; write() возвращает число изменённых строк.
    final updated = await (_db.update(_db.notes)..where((n) => n.id.equals(id)))
        .write(
          // Меняются только перечисленные поля, остальные остаются как были.
          NotesCompanion(
            title: Value(title.trim()),
            body: Value(body.trim()),
            updatedAt: Value(DateTime.now()),
          ),
        );
    // Ни одна строка не изменилась — значит, заметку уже удалили.
    if (updated == 0) throw const AppException('Заметка не найдена');
  }

  /// Удаляет заметку по id (DELETE FROM notes WHERE id = ?).
  @override
  Future<void> deleteNote(int id) =>
      (_db.delete(_db.notes)..where((n) => n.id.equals(id))).go();

  /// Переводит строку таблицы [NoteRow] в сущность [Note] слоя domain,
  /// чтобы остальной код не зависел от drift.
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

/// Журнал завершённых «помидоров» (таблица `pomodoro_logs`).
///
/// «Помидор» (Pomodoro) — отрезок сосредоточенной работы по таймеру.
class PomodoroRepositoryImpl implements PomodoroRepository {
  /// Получает объект базы данных, общий для всего приложения.
  PomodoroRepositoryImpl(this._db);

  /// База данных приложения.
  final AppDatabase _db;

  /// Записывает в журнал завершённый «помидор» длиной [minutes] минут.
  ///
  /// [topicTitle] — название темы, если таймер был запущен для темы.
  @override
  Future<void> logPomodoro({
    required int userId,
    required int minutes,
    String? topicTitle,
  }) => _db
      // INSERT в таблицу pomodoro_logs.
      .into(_db.pomodoroLogs)
      .insert(
        PomodoroLogsCompanion.insert(
          userId: userId,
          minutes: minutes,
          topicTitle: Value(topicTitle),
          // Время завершения — текущий момент.
          completedAt: DateTime.now(),
        ),
      );

  /// Поток всех «помидоров» пользователя, последние сверху.
  @override
  Stream<List<PomodoroEntry>> watchPomodoros(int userId) =>
      // SELECT из pomodoro_logs только для этого пользователя,
      // сортировка по времени завершения от новых к старым.
      (_db.select(_db.pomodoroLogs)
            ..where((p) => p.userId.equals(userId))
            ..orderBy([(p) => OrderingTerm.desc(p.completedAt)]))
          // Следим за таблицей: при новой записи придёт новый список.
          .watch()
          .map(
            // Каждую строку базы переводим в сущность PomodoroEntry.
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
