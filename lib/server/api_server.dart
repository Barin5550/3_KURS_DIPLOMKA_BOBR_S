// Сервер API «Маршрута»: принимает HTTP-запросы приложения и работает с
// базой данных SQLite. Это серверная часть проекта: в само приложение на
// телефоне она не входит. Сервер переиспользует репозитории
// lib/data/repositories (запросы к базе через drift) и переводит данные в
// JSON функциями lib/data/api/api_json.dart.
// Запускается программой bin/marshrut_server.dart, а в тестах — прямо в
// памяти, без сети (test/server/api_server_test.dart).
//
// Правила API:
// - адреса начинаются с /api, данные передаются в формате JSON;
// - после входа сервер выдаёт токен, и каждый запрос к данным пользователя
//   несёт его в заголовке `Authorization: Bearer <токен>`;
// - пользователь видит и меняет только свои данные: чужой план или
//   заметка для него «не найдены» (код 404);
// - при ошибке сервер отвечает кодом 400/401/404/500 и JSON
//   `{"error": "текст ошибки"}`.
// Полный список адресов — docs/API.md.

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../core/utils/password_hasher.dart';
import '../core/utils/validators.dart';
import '../data/api/api_json.dart';
import '../data/db/app_database.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../data/repositories/note_repository_impl.dart';
import '../data/repositories/plan_repository_impl.dart';
import '../data/repositories/topic_repository_impl.dart';
import '../domain/entities/session.dart';
import '../domain/repositories/repositories.dart';

/// Ошибка обработки запроса: код ответа HTTP и текст для пользователя.
class HttpError implements Exception {
  /// [statusCode] — код ответа, [message] — текст ошибки.
  const HttpError(this.statusCode, this.message);

  /// Код ответа HTTP (400, 401, 404 …).
  final int statusCode;

  /// Текст ошибки, который увидит пользователь.
  final String message;
}

/// Сервер API: маршруты (какой адрес что делает) и их обработчики.
class ApiServer {
  /// [db] — база SQLite; [catalog] — направления и темы в виде JSON (как в
  /// файлах assets/catalog); [hasher] — хэширование паролей (в тестах —
  /// быстрое); [log] — куда писать журнал запросов; [clock] — текущее время.
  ApiServer({
    required this.db,
    required this.catalog,
    PasswordHasher? hasher,
    this.log,
    this.tokenLifetime = const Duration(days: 30),
    DateTime Function()? clock,
  }) : _auth = AuthRepositoryImpl(db, hasher: hasher),
       _plans = PlanRepositoryImpl(db),
       _topics = TopicRepositoryImpl(db),
       _notes = NoteRepositoryImpl(db),
       _pomodoros = PomodoroRepositoryImpl(db),
       _clock = clock ?? DateTime.now;

  /// Версия API: приложение может проверить её через /api/health.
  static const apiVersion = 1;

  /// База данных сервера.
  final AppDatabase db;

  /// Каталог направлений (JSON-объекты из файлов assets/catalog).
  final List<Object?> catalog;

  /// Журнал: сюда пишется строка о каждом запросе. `null` — без журнала.
  final void Function(String line)? log;

  /// Сколько действует токен входа.
  final Duration tokenLifetime;

  /// Репозиторий пользователей (регистрация, вход, профиль).
  final AuthRepositoryImpl _auth;

  /// Репозиторий планов, тем плана и занятий.
  final PlanRepositoryImpl _plans;

  /// Репозиторий своих тем и избранного.
  final TopicRepositoryImpl _topics;

  /// Репозиторий заметок.
  final NoteRepositoryImpl _notes;

  /// Репозиторий журнала Pomodoro.
  final PomodoroRepositoryImpl _pomodoros;

  /// Источник текущего времени.
  final DateTime Function() _clock;

  /// Криптостойкий генератор случайных чисел для токенов.
  final _random = Random.secure();

  /// Обработчик всех запросов. Pipeline — цепочка «прослоек» (middleware):
  /// сначала журнал, затем перехват ошибок, затем нужный маршрут.
  late final Handler handler = const Pipeline()
      .addMiddleware(_logRequests)
      .addMiddleware(_handleErrors)
      .addHandler(_buildRouter().call);

  /// Таблица маршрутов: метод HTTP + адрес → функция-обработчик.
  /// `<id|[0-9]+>` — часть адреса, которая передаётся в обработчик (только
  /// цифры).
  Router _buildRouter() {
    final r = Router(notFoundHandler: (_) => _error(404, 'Адрес не найден'));

    // Служебные адреса: страница сервера, проверка связи, каталог.
    r.get('/', _home);
    r.get('/api/health', _health);
    r.get('/api/directions', (Request _) => _json(catalog));

    // Регистрация, вход, выход и профиль.
    r.post('/api/auth/register', _register);
    r.post('/api/auth/login', _login);
    r.post('/api/auth/logout', _logout);
    r.get('/api/me', _me);
    r.put('/api/me', _updateProfile);
    r.delete('/api/me', _deleteAccount);
    r.put('/api/me/password', _changePassword);
    r.put('/api/me/reminder', _updateReminder);

    // Планы обучения.
    r.get('/api/plans', _listPlans);
    r.post('/api/plans', _createPlan);
    r.get('/api/plans/active', _activePlan);
    r.get('/api/plans/<id|[0-9]+>', _getPlan);
    r.patch('/api/plans/<id|[0-9]+>', _renamePlan);
    r.delete('/api/plans/<id|[0-9]+>', _deletePlan);
    r.post('/api/plans/<id|[0-9]+>/activate', _activatePlan);
    r.put('/api/plans/<id|[0-9]+>/settings', _updateSettings);
    r.get('/api/plans/<id|[0-9]+>/topics', _planTopics);
    r.put('/api/plans/<id|[0-9]+>/topics', _replacePlanTopics);
    r.get('/api/plans/<id|[0-9]+>/sessions', _planSessions);
    r.put('/api/plans/<id|[0-9]+>/sessions/open', _replaceOpenSessions);

    // Занятия.
    r.get('/api/sessions/completed', _completedSessions);
    r.get('/api/sessions/<id|[0-9]+>', _getSession);
    r.put('/api/sessions/<id|[0-9]+>/done', _setSessionDone);

    // Свои темы и избранное.
    r.get('/api/custom-topics', _listCustomTopics);
    r.post('/api/custom-topics', _createCustomTopic);
    r.get('/api/custom-topics/<id>', _getCustomTopic);
    r.put('/api/custom-topics/<id>', _updateCustomTopic);
    r.delete('/api/custom-topics/<id>', _deleteCustomTopic);
    r.get('/api/favorites', _favorites);
    r.post('/api/favorites/<topicId>/toggle', _toggleFavorite);

    // Заметки.
    r.get('/api/notes', _listNotes);
    r.post('/api/notes', _createNote);
    r.get('/api/notes/<id|[0-9]+>', _getNote);
    r.put('/api/notes/<id|[0-9]+>', _updateNote);
    r.delete('/api/notes/<id|[0-9]+>', _deleteNote);

    // Журнал Pomodoro.
    r.get('/api/pomodoros', _listPomodoros);
    r.post('/api/pomodoros', _logPomodoro);
    return r;
  }

  // ---------------------------------------------------------------------
  // Прослойки (middleware)
  // ---------------------------------------------------------------------

  /// Пишет в журнал строку о каждом запросе: время, метод, адрес, код
  /// ответа и сколько миллисекунд занял ответ.
  Handler _logRequests(Handler inner) => (request) async {
    // Засекаем время обработки.
    final watch = Stopwatch()..start();
    final response = await inner(request);
    // Время в виде ЧЧ:ММ:СС.
    final now = _clock().toIso8601String().substring(11, 19);
    final query = request.url.hasQuery ? '?${request.url.query}' : '';
    log?.call(
      '$now  ${request.method.padRight(6)} /${request.url.path}$query'
      '  →  ${response.statusCode}  (${watch.elapsedMilliseconds} мс)',
    );
    return response;
  };

  /// Перехватывает ошибки обработчиков и превращает их в ответ JSON с
  /// нужным кодом: так приложение всегда получает понятный текст ошибки.
  Handler _handleErrors(Handler inner) => (request) async {
    try {
      return await inner(request);
    } on HttpError catch (e) {
      // Ошибка, которую обработчик выбросил сам (401, 404 …).
      return _error(e.statusCode, e.message);
    } on AppException catch (e) {
      // Ошибка правил приложения: «email уже занят», «неверный пароль» …
      return _error(400, e.message);
    } on FormatException {
      // Неверный формат данных (например, дата не в формате ISO 8601).
      return _error(400, 'Некорректные данные в запросе');
    } on TypeError {
      // В JSON поле другого типа, чем ожидалось (строка вместо числа …).
      return _error(400, 'Некорректные данные в запросе');
    } on Object catch (e, stack) {
      // Непредвиденная ошибка: подробности — только в журнал сервера.
      log?.call('Ошибка сервера: $e\n$stack');
      return _error(500, 'Внутренняя ошибка сервера');
    }
  };

  // ---------------------------------------------------------------------
  // Вспомогательные функции
  // ---------------------------------------------------------------------

  /// Ответ с телом JSON. [status] — код ответа (по умолчанию 200 «OK»).
  Response _json(Object? body, {int status = 200}) => Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  /// Ответ 201 «Создано» с идентификатором новой записи.
  Response _created(Object id) => _json({'id': id}, status: 201);

  /// Ответ 204 «Нет содержимого»: действие выполнено, данных в ответе нет.
  Response _noContent() => Response(204);

  /// Ответ с ошибкой: код [status] и JSON `{"error": message}`.
  Response _error(int status, String message) =>
      _json({'error': message}, status: status);

  /// Читает тело запроса как JSON-объект.
  Future<Json> _body(Request request) async {
    final text = await request.readAsString();
    try {
      final data = jsonDecode(text);
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // Ниже ответим той же ошибкой, что и для не-объекта.
    }
    throw const HttpError(400, 'Тело запроса должно быть объектом JSON');
  }

  /// Достаёт из JSON обязательное поле типа [T] или отвечает ошибкой 400.
  T _field<T>(Json body, String name) {
    final value = body[name];
    if (value is T) return value;
    throw HttpError(400, 'Поле «$name» не заполнено или имеет неверный тип');
  }

  /// Необязательное поле типа [T]: `null`, если его нет.
  T? _optional<T>(Json body, String name) {
    final value = body[name];
    if (value == null || value is T) return value as T?;
    throw HttpError(400, 'Поле «$name» имеет неверный тип');
  }

  /// Список JSON-объектов из поля [name].
  List<Json> _objects(Json body, String name) =>
      _field<List<dynamic>>(body, name).cast<Json>();

  /// Повторная проверка данных на сервере теми же правилами, что и в
  /// формах приложения: первая найденная ошибка уходит ответом 400.
  void _validate(List<String?> errors) {
    for (final error in errors) {
      if (error != null) throw HttpError(400, error);
    }
  }

  /// Хэш токена SHA-256: в базе хранится он, а не сам токен.
  static String _hashToken(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  /// Выдаёт новый токен входа пользователю [userId] и возвращает его.
  /// Токен — 32 случайных байта в виде строки base64url.
  Future<String> issueToken(int userId) async {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final token = base64Url.encode(bytes).replaceAll('=', '');
    await db
        .into(db.apiTokens)
        .insert(
          ApiTokensCompanion.insert(
            tokenHash: _hashToken(token),
            userId: userId,
            createdAt: _clock(),
          ),
        );
    return token;
  }

  /// Токен из заголовка `Authorization: Bearer <токен>` или `null`.
  String? _tokenOf(Request request) {
    final header = request.headers['authorization'];
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length).trim();
  }

  /// Определяет по токену, какой пользователь отправил запрос.
  /// Без токена или с устаревшим токеном — ошибка 401.
  Future<int> _userId(Request request) async {
    final token = _tokenOf(request);
    if (token == null) throw const HttpError(401, 'Требуется вход в аккаунт');
    // Ищем в базе запись с хэшем этого токена.
    final row = await (db.select(
      db.apiTokens,
    )..where((t) => t.tokenHash.equals(_hashToken(token)))).getSingleOrNull();
    // Токена нет или он старше срока действия.
    if (row == null || _clock().difference(row.createdAt) > tokenLifetime) {
      throw const HttpError(401, 'Сессия истекла, войдите снова');
    }
    return row.userId;
  }

  /// Проверяет, что план [planId] принадлежит пользователю [userId].
  Future<void> _ownPlan(int userId, int planId) async {
    final plan = await _plans.planById(planId);
    if (plan == null || plan.userId != userId) {
      throw const HttpError(404, 'План не найден');
    }
  }

  /// Возвращает занятие [sessionId], если оно из плана пользователя.
  Future<StudySession> _ownSession(int userId, int sessionId) async {
    final session = await _plans.sessionById(sessionId);
    final plan = session == null ? null : await _plans.planById(session.planId);
    if (session == null || plan == null || plan.userId != userId) {
      throw const HttpError(404, 'Занятие не найдено');
    }
    return session;
  }

  /// Возвращает строку своей темы [topicId], если тема принадлежит
  /// пользователю [userId]. id своей темы выглядит как `custom_12`.
  Future<CustomTopicRow> _ownCustomTopic(int userId, String topicId) async {
    final id = TopicRepositoryImpl.isCustomId(topicId)
        ? int.tryParse(
            topicId.substring(TopicRepositoryImpl.customPrefix.length),
          )
        : null;
    final row = id == null
        ? null
        : await (db.select(db.customTopics)
                ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
              .getSingleOrNull();
    if (row == null) throw const HttpError(404, 'Тема не найдена');
    return row;
  }

  /// Проверяет, что заметка [noteId] принадлежит пользователю [userId].
  Future<void> _ownNote(int userId, int noteId) async {
    final note = await _notes.noteById(noteId);
    if (note == null || note.userId != userId) {
      throw const HttpError(404, 'Заметка не найдена');
    }
  }

  // ---------------------------------------------------------------------
  // Служебные адреса
  // ---------------------------------------------------------------------

  /// GET / — страница сервера для браузера: видно, что сервер работает и
  /// сколько данных в базе. Удобно проверить связь с телефона.
  Future<Response> _home(Request request) async {
    final users = await db.users.count().getSingle();
    final plans = await db.plans.count().getSingle();
    final notes = await db.notes.count().getSingle();
    final html =
        '''
<!doctype html>
<html lang="ru">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Сервер «Маршрут»</title></head>
<body style="font-family: sans-serif; max-width: 640px; margin: 32px auto; padding: 0 16px; line-height: 1.5">
<h1 style="color: #1A3A8F">Сервер «Маршрут» работает</h1>
<p>Это сервер API приложения «Маршрут». Приложение получает и сохраняет все данные через адреса, которые начинаются с <code>/api</code>.</p>
<p>В базе: пользователей — $users, планов — $plans, заметок — $notes.</p>
<p>Проверка связи: <a href="/api/health">/api/health</a><br>Каталог тем: <a href="/api/directions">/api/directions</a></p>
</body>
</html>''';
    return Response.ok(
      html,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  /// GET /api/health — проверка связи: приложение вызывает его, когда
  /// пользователь сохраняет адрес сервера.
  Response _health(Request request) =>
      _json({'status': 'ok', 'service': 'Маршрут', 'version': apiVersion});

  // ---------------------------------------------------------------------
  // Пользователь
  // ---------------------------------------------------------------------

  /// POST /api/auth/register — регистрация. Тело: name, email, password.
  /// Ответ 201 с данными пользователя.
  Future<Response> _register(Request request) async {
    final body = await _body(request);
    final name = _field<String>(body, 'name');
    final email = _field<String>(body, 'email');
    final password = _field<String>(body, 'password');
    // Те же правила, что и в форме регистрации.
    _validate([
      Validators.name(name),
      Validators.email(email),
      Validators.password(password),
    ]);
    final user = await _auth.register(
      name: name,
      email: email,
      password: password,
    );
    return _json(userToJson(user), status: 201);
  }

  /// POST /api/auth/login — вход. Тело: email, password.
  /// Ответ: токен и данные пользователя.
  Future<Response> _login(Request request) async {
    final body = await _body(request);
    final user = await _auth.login(
      email: _field<String>(body, 'email'),
      password: _field<String>(body, 'password'),
    );
    final token = await issueToken(user.id);
    return _json({'token': token, 'user': userToJson(user)});
  }

  /// POST /api/auth/logout — выход: токен удаляется и больше не действует.
  Future<Response> _logout(Request request) async {
    final token = _tokenOf(request);
    if (token != null) {
      await (db.delete(
        db.apiTokens,
      )..where((t) => t.tokenHash.equals(_hashToken(token)))).go();
    }
    return _noContent();
  }

  /// GET /api/me — данные вошедшего пользователя.
  Future<Response> _me(Request request) async {
    final user = await _auth.userById(await _userId(request));
    // Аккаунт удалён, а токен остался у приложения.
    if (user == null) throw const HttpError(401, 'Пользователь не найден');
    return _json(userToJson(user));
  }

  /// PUT /api/me — изменение профиля. Тело: name, email, avatarColor.
  Future<Response> _updateProfile(Request request) async {
    final userId = await _userId(request);
    final body = await _body(request);
    final name = _field<String>(body, 'name');
    final email = _field<String>(body, 'email');
    _validate([Validators.name(name), Validators.email(email)]);
    final user = await _auth.updateProfile(
      userId: userId,
      name: name,
      email: email,
      avatarColor: _field<int>(body, 'avatarColor'),
    );
    return _json(userToJson(user));
  }

  /// PUT /api/me/password — смена пароля. Тело: oldPassword, newPassword.
  Future<Response> _changePassword(Request request) async {
    final userId = await _userId(request);
    final body = await _body(request);
    final newPassword = _field<String>(body, 'newPassword');
    _validate([Validators.password(newPassword)]);
    await _auth.changePassword(
      userId: userId,
      oldPassword: _field<String>(body, 'oldPassword'),
      newPassword: newPassword,
    );
    return _noContent();
  }

  /// PUT /api/me/reminder — настройки напоминания.
  /// Тело: enabled, hour (0–23), minute (0–59).
  Future<Response> _updateReminder(Request request) async {
    final userId = await _userId(request);
    final body = await _body(request);
    final hour = _field<int>(body, 'hour');
    final minute = _field<int>(body, 'minute');
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw const HttpError(400, 'Неверное время напоминания');
    }
    final user = await _auth.updateReminder(
      userId: userId,
      enabled: _field<bool>(body, 'enabled'),
      hour: hour,
      minute: minute,
    );
    return _json(userToJson(user));
  }

  /// DELETE /api/me — удаление аккаунта со всеми данными.
  /// Тело: password (подтверждение паролем).
  Future<Response> _deleteAccount(Request request) async {
    final userId = await _userId(request);
    final body = await _body(request);
    await _auth.deleteAccount(
      userId: userId,
      password: _field<String>(body, 'password'),
    );
    return _noContent();
  }

  // ---------------------------------------------------------------------
  // Планы и занятия
  // ---------------------------------------------------------------------

  /// GET /api/plans — все планы пользователя, новые первыми.
  Future<Response> _listPlans(Request request) async {
    final plans = await _plans.watchPlans(await _userId(request)).first;
    return _json(plans.map(planToJson).toList());
  }

  /// GET /api/plans/active — активный план или `null`, если планов нет.
  Future<Response> _activePlan(Request request) async {
    final plan = await _plans.watchActivePlan(await _userId(request)).first;
    return _json(plan == null ? null : planToJson(plan));
  }

  /// POST /api/plans — сохранение нового плана, который приложение
  /// составило алгоритмом. Тело: directionId, title, settings,
  /// knownTopicIds, orderedTopics, sessions. Новый план становится активным.
  Future<Response> _createPlan(Request request) async {
    final userId = await _userId(request);
    final body = await _body(request);
    final title = _field<String>(body, 'title');
    _validate([Validators.title(title)]);
    final id = await _plans.createPlan(
      userId: userId,
      directionId: _field<String>(body, 'directionId'),
      title: title,
      settings: settingsFromJson(_field<Json>(body, 'settings')),
      knownTopicIds: stringsFromJson(body['knownTopicIds']).toSet(),
      orderedTopics: _objects(
        body,
        'orderedTopics',
      ).map(topicFromJson).toList(),
      sessions: _objects(body, 'sessions').map(plannedSessionFromJson).toList(),
    );
    return _created(id);
  }

  /// GET /api/plans/{id} — один план.
  Future<Response> _getPlan(Request request, String id) async {
    final planId = int.parse(id);
    await _ownPlan(await _userId(request), planId);
    return _json(planToJson((await _plans.planById(planId))!));
  }

  /// PATCH /api/plans/{id} — переименование. Тело: title.
  Future<Response> _renamePlan(Request request, String id) async {
    final planId = int.parse(id);
    await _ownPlan(await _userId(request), planId);
    final title = _field<String>(await _body(request), 'title');
    _validate([Validators.title(title)]);
    await _plans.renamePlan(planId, title);
    return _noContent();
  }

  /// DELETE /api/plans/{id} — удаление плана с его темами и занятиями.
  Future<Response> _deletePlan(Request request, String id) async {
    final planId = int.parse(id);
    await _ownPlan(await _userId(request), planId);
    await _plans.deletePlan(planId);
    return _noContent();
  }

  /// POST /api/plans/{id}/activate — сделать план активным.
  Future<Response> _activatePlan(Request request, String id) async {
    final userId = await _userId(request);
    final planId = int.parse(id);
    await _ownPlan(userId, planId);
    await _plans.setActive(userId, planId);
    return _noContent();
  }

  /// PUT /api/plans/{id}/settings — новые настройки расписания.
  /// Тело: hoursPerWeek, studyDays, startDate, deadline.
  Future<Response> _updateSettings(Request request, String id) async {
    final planId = int.parse(id);
    await _ownPlan(await _userId(request), planId);
    final settings = settingsFromJson(await _body(request));
    if (settings.studyDays.isEmpty || settings.hoursPerWeek <= 0) {
      throw const HttpError(400, 'Выберите дни занятий и часы в неделю');
    }
    await _plans.updateSettings(planId, settings);
    return _noContent();
  }

  /// GET /api/plans/{id}/topics — темы плана в порядке изучения.
  Future<Response> _planTopics(Request request, String id) async {
    final planId = int.parse(id);
    await _ownPlan(await _userId(request), planId);
    final topics = await _plans.planTopics(planId);
    return _json(topics.map(planTopicToJson).toList());
  }

  /// PUT /api/plans/{id}/topics — новый список тем плана (после
  /// перепланирования). Тело: topics.
  Future<Response> _replacePlanTopics(Request request, String id) async {
    final planId = int.parse(id);
    await _ownPlan(await _userId(request), planId);
    final topics = _objects(await _body(request), 'topics');
    await _plans.replacePlanTopics(planId, topics.map(topicFromJson).toList());
    return _noContent();
  }

  /// GET /api/plans/{id}/sessions — все занятия плана.
  Future<Response> _planSessions(Request request, String id) async {
    final planId = int.parse(id);
    await _ownPlan(await _userId(request), planId);
    final sessions = await _plans.sessions(planId);
    return _json(sessions.map(studySessionToJson).toList());
  }

  /// PUT /api/plans/{id}/sessions/open — заменить невыполненные занятия
  /// новым расписанием (перепланирование). Тело: sessions.
  Future<Response> _replaceOpenSessions(Request request, String id) async {
    final planId = int.parse(id);
    await _ownPlan(await _userId(request), planId);
    final sessions = _objects(await _body(request), 'sessions');
    await _plans.replaceOpenSessions(
      planId,
      sessions.map(plannedSessionFromJson).toList(),
    );
    return _noContent();
  }

  /// GET /api/sessions/completed — выполненные занятия всех планов
  /// пользователя (для статистики и истории).
  Future<Response> _completedSessions(Request request) async {
    final userId = await _userId(request);
    final sessions = await _plans.watchCompletedSessions(userId).first;
    return _json(sessions.map(studySessionToJson).toList());
  }

  /// GET /api/sessions/{id} — одно занятие.
  Future<Response> _getSession(Request request, String id) async {
    final session = await _ownSession(await _userId(request), int.parse(id));
    return _json(studySessionToJson(session));
  }

  /// PUT /api/sessions/{id}/done — отметить занятие выполненным или снять
  /// отметку. Тело: done (true/false).
  Future<Response> _setSessionDone(Request request, String id) async {
    final session = await _ownSession(await _userId(request), int.parse(id));
    final done = _field<bool>(await _body(request), 'done');
    await _plans.setSessionDone(session.id, done: done);
    return _noContent();
  }

  // ---------------------------------------------------------------------
  // Свои темы и избранное
  // ---------------------------------------------------------------------

  /// GET /api/custom-topics?directionId=... — свои темы (все или одного
  /// направления).
  Future<Response> _listCustomTopics(Request request) async {
    final userId = await _userId(request);
    final directionId = request.url.queryParameters['directionId'];
    final topics = await _topics
        .watchCustomTopics(userId, directionId: directionId)
        .first;
    return _json(topics.map(topicToJson).toList());
  }

  /// Проверяет поля своей темы и возвращает их.
  ({
    String title,
    String description,
    int minutes,
    String category,
    List<String> prerequisites,
  })
  _topicFields(Json body) {
    final title = _field<String>(body, 'title');
    final category = _field<String>(body, 'category');
    final minutes = _field<int>(body, 'minutes');
    _validate([
      Validators.title(title),
      Validators.requiredText(category, field: 'категорию'),
      // От 30 минут до 100 часов — как в форме своей темы.
      minutes < 30 || minutes > 6000 ? 'От 0,5 до 100 часов' : null,
    ]);
    return (
      title: title,
      description: _optional<String>(body, 'description') ?? '',
      minutes: minutes,
      category: category,
      prerequisites: stringsFromJson(body['prerequisites']),
    );
  }

  /// POST /api/custom-topics — новая своя тема. Тело: directionId, title,
  /// description, minutes, category, prerequisites. Ответ 201 с id.
  Future<Response> _createCustomTopic(Request request) async {
    final userId = await _userId(request);
    final body = await _body(request);
    final fields = _topicFields(body);
    final id = await _topics.createCustomTopic(
      userId: userId,
      directionId: _field<String>(body, 'directionId'),
      title: fields.title,
      description: fields.description,
      minutes: fields.minutes,
      category: fields.category,
      prerequisites: fields.prerequisites,
    );
    return _created(id);
  }

  /// GET /api/custom-topics/{id} — своя тема и её направление.
  Future<Response> _getCustomTopic(Request request, String id) async {
    final row = await _ownCustomTopic(await _userId(request), id);
    final topic = (await _topics.customTopicById(id))!;
    return _json({...topicToJson(topic), 'directionId': row.directionId});
  }

  /// PUT /api/custom-topics/{id} — изменение своей темы.
  Future<Response> _updateCustomTopic(Request request, String id) async {
    await _ownCustomTopic(await _userId(request), id);
    final fields = _topicFields(await _body(request));
    await _topics.updateCustomTopic(
      topicId: id,
      title: fields.title,
      description: fields.description,
      minutes: fields.minutes,
      category: fields.category,
      prerequisites: fields.prerequisites,
    );
    return _noContent();
  }

  /// DELETE /api/custom-topics/{id} — удаление своей темы.
  Future<Response> _deleteCustomTopic(Request request, String id) async {
    await _ownCustomTopic(await _userId(request), id);
    await _topics.deleteCustomTopic(id);
    return _noContent();
  }

  /// GET /api/favorites — id избранных тем.
  Future<Response> _favorites(Request request) async {
    final ids = await _topics.watchFavorites(await _userId(request)).first;
    return _json(ids.toList()..sort());
  }

  /// POST /api/favorites/{topicId}/toggle — добавить тему в избранное или
  /// убрать из него.
  Future<Response> _toggleFavorite(Request request, String topicId) async {
    await _topics.toggleFavorite(await _userId(request), topicId);
    return _noContent();
  }

  // ---------------------------------------------------------------------
  // Заметки и Pomodoro
  // ---------------------------------------------------------------------

  /// GET /api/notes?topicId=... — заметки пользователя (все или к теме).
  Future<Response> _listNotes(Request request) async {
    final userId = await _userId(request);
    final topicId = request.url.queryParameters['topicId'];
    final notes = await _notes.watchNotes(userId, topicId: topicId).first;
    return _json(notes.map(noteToJson).toList());
  }

  /// POST /api/notes — новая заметка. Тело: title, body, topicId,
  /// topicTitle. Ответ 201 с id.
  Future<Response> _createNote(Request request) async {
    final userId = await _userId(request);
    final body = await _body(request);
    final title = _field<String>(body, 'title');
    final text = _field<String>(body, 'body');
    _validate([
      Validators.title(title),
      Validators.requiredText(text, field: 'текст заметки'),
    ]);
    final id = await _notes.createNote(
      userId: userId,
      title: title,
      body: text,
      topicId: _optional<String>(body, 'topicId'),
      topicTitle: _optional<String>(body, 'topicTitle'),
    );
    return _created(id);
  }

  /// GET /api/notes/{id} — одна заметка.
  Future<Response> _getNote(Request request, String id) async {
    final noteId = int.parse(id);
    await _ownNote(await _userId(request), noteId);
    return _json(noteToJson((await _notes.noteById(noteId))!));
  }

  /// PUT /api/notes/{id} — изменение заметки. Тело: title, body.
  Future<Response> _updateNote(Request request, String id) async {
    final noteId = int.parse(id);
    await _ownNote(await _userId(request), noteId);
    final body = await _body(request);
    final title = _field<String>(body, 'title');
    final text = _field<String>(body, 'body');
    _validate([
      Validators.title(title),
      Validators.requiredText(text, field: 'текст заметки'),
    ]);
    await _notes.updateNote(id: noteId, title: title, body: text);
    return _noContent();
  }

  /// DELETE /api/notes/{id} — удаление заметки.
  Future<Response> _deleteNote(Request request, String id) async {
    final noteId = int.parse(id);
    await _ownNote(await _userId(request), noteId);
    await _notes.deleteNote(noteId);
    return _noContent();
  }

  /// GET /api/pomodoros — завершённые интервалы Pomodoro.
  Future<Response> _listPomodoros(Request request) async {
    final entries = await _pomodoros
        .watchPomodoros(await _userId(request))
        .first;
    return _json(entries.map(pomodoroToJson).toList());
  }

  /// POST /api/pomodoros — записать завершённый интервал.
  /// Тело: minutes, topicTitle.
  Future<Response> _logPomodoro(Request request) async {
    final userId = await _userId(request);
    final body = await _body(request);
    final minutes = _field<int>(body, 'minutes');
    if (minutes <= 0) throw const HttpError(400, 'Неверная длительность');
    await _pomodoros.logPomodoro(
      userId: userId,
      minutes: minutes,
      topicTitle: _optional<String>(body, 'topicTitle'),
    );
    return _json(const <String, Object>{}, status: 201);
  }
}
