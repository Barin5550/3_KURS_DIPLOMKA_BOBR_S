// Заметки и журнал Pomodoro через API.
// Слой: data. Реализует интерфейсы NoteRepository и PomodoroRepository
// запросами к серверу (адреса /api/notes и /api/pomodoros). Заметки —
// главный пример полного CRUD через API: получение (GET), добавление
// (POST), изменение (PUT) и удаление (DELETE).

import '../../domain/entities/note.dart';
import '../../domain/repositories/repositories.dart';
import 'api_client.dart';
import 'api_json.dart';

/// Репозиторий заметок, работающий через сервер API.
class ApiNoteRepository implements NoteRepository {
  /// [api] — клиент, через который идут запросы.
  ApiNoteRepository(this._api);

  /// Клиент API.
  final ApiClient _api;

  /// GET /api/notes?topicId=... — поток заметок (все или к одной теме).
  @override
  Stream<List<Note>> watchNotes(int userId, {String? topicId}) =>
      _api.watch(() async {
        final data = await _api.get(
          '/api/notes',
          query: topicId == null ? null : {'topicId': topicId},
        );
        return (data as List<dynamic>).cast<Json>().map(noteFromJson).toList();
      });

  /// GET /api/notes/{id} — одна заметка; `null`, если не найдена.
  @override
  Future<Note?> noteById(int id) async {
    try {
      return noteFromJson(await _api.get('/api/notes/$id') as Json);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST /api/notes — новая заметка; возвращает её id.
  @override
  Future<int> createNote({
    required int userId,
    required String title,
    required String body,
    String? topicId,
    String? topicTitle,
  }) async {
    final data = await _api.post('/api/notes', {
      'title': title,
      'body': body,
      'topicId': topicId,
      'topicTitle': topicTitle,
    }) as Json;
    return data['id'] as int;
  }

  /// PUT /api/notes/{id} — изменение заметки.
  @override
  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  }) => _api.put('/api/notes/$id', {'title': title, 'body': body});

  /// DELETE /api/notes/{id} — удаление заметки.
  @override
  Future<void> deleteNote(int id) => _api.delete('/api/notes/$id');
}

/// Журнал Pomodoro, работающий через сервер API.
class ApiPomodoroRepository implements PomodoroRepository {
  /// [api] — клиент, через который идут запросы.
  ApiPomodoroRepository(this._api);

  /// Клиент API.
  final ApiClient _api;

  /// POST /api/pomodoros — записать завершённый интервал.
  @override
  Future<void> logPomodoro({
    required int userId,
    required int minutes,
    String? topicTitle,
  }) => _api.post('/api/pomodoros', {
    'minutes': minutes,
    'topicTitle': topicTitle,
  });

  /// GET /api/pomodoros — поток завершённых интервалов.
  @override
  Stream<List<PomodoroEntry>> watchPomodoros(int userId) => _api.watch(
    () async => (await _api.get('/api/pomodoros') as List<dynamic>)
        .cast<Json>()
        .map(pomodoroFromJson)
        .toList(),
  );
}
