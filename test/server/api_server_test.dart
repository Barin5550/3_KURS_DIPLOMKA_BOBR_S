import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/data/api/api_client.dart';
import 'package:marshrut/data/api/api_plan_repository.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/domain/entities/schedule_settings.dart';
import 'package:marshrut/domain/entities/topic.dart';
import 'package:marshrut/domain/usecases/plan_service.dart';
import 'package:marshrut/server/api_server.dart';
import 'package:shelf/shelf.dart';

import '../helpers/test_app.dart';

/// Ответ сервера в тестах: код и разобранное тело JSON.
typedef Reply = ({int status, dynamic body});

/// Тесты сервера API: адреса, коды ответов, токены, проверка данных и
/// то, что чужие данные недоступны.
void main() {
  late AppDatabase db;
  late ApiServer server;

  setUp(() {
    db = memoryDatabase();
    server = testServer(db);
  });
  tearDown(() => db.close());

  /// Отправляет запрос прямо в обработчик сервера (без сети).
  /// [body] переводится в JSON, [raw] уходит как есть.
  Future<Reply> call(
    String method,
    String path, {
    Object? body,
    String? raw,
    String? token,
    ApiServer? to,
  }) async {
    final response = await (to ?? server).handler(
      Request(
        method,
        Uri.parse('http://localhost$path'),
        headers: {
          'content-type': 'application/json',
          if (token != null) 'authorization': 'Bearer $token',
        },
        body: raw ?? (body == null ? null : jsonEncode(body)),
      ),
    );
    final text = await response.readAsString();
    return (
      status: response.statusCode,
      body: text.isEmpty ? null : jsonDecode(text),
    );
  }

  /// Регистрирует пользователя и входит: возвращает токен.
  Future<String> signIn([String email = 'user@mail.ru']) async {
    final reg = await call(
      'POST',
      '/api/auth/register',
      body: {'name': 'Алия', 'email': email, 'password': 'secret123'},
    );
    expect(reg.status, 201);
    final login = await call(
      'POST',
      '/api/auth/login',
      body: {'email': email, 'password': 'secret123'},
    );
    expect(login.status, 200);
    return login.body['token'] as String;
  }

  group('служебные адреса', () {
    test('проверка связи и каталог', () async {
      final health = await call('GET', '/api/health');
      expect(health.status, 200);
      expect(health.body, {'status': 'ok', 'service': 'Маршрут', 'version': 1});

      final directions = await call('GET', '/api/directions');
      expect(directions.status, 200);
      expect(directions.body, hasLength(catalogJson().length));
    });

    test('страница сервера для браузера', () async {
      final response = await server.handler(
        Request('GET', Uri.parse('http://localhost/')),
      );
      expect(response.statusCode, 200);
      expect(response.headers['content-type'], startsWith('text/html'));
      expect(await response.readAsString(), contains('работает'));
    });

    test('неизвестный адрес — 404 с текстом ошибки', () async {
      final reply = await call('GET', '/api/unknown');
      expect(reply.status, 404);
      expect(reply.body, {'error': 'Адрес не найден'});
    });
  });

  group('регистрация, вход и токены', () {
    test('регистрация возвращает 201 и не отдаёт хэш пароля', () async {
      final reply = await call(
        'POST',
        '/api/auth/register',
        body: {'name': 'Алия', 'email': 'a@mail.ru', 'password': 'secret123'},
      );
      expect(reply.status, 201);
      expect(reply.body['email'], 'a@mail.ru');
      expect(jsonEncode(reply.body), isNot(contains('hash')));
      expect(jsonEncode(reply.body), isNot(contains('secret123')));
    });

    test('сервер сам проверяет поля и занятый email', () async {
      final bad = await call(
        'POST',
        '/api/auth/register',
        body: {'name': 'Алия', 'email': 'не-email', 'password': 'secret123'},
      );
      expect(bad.status, 400);
      expect(bad.body['error'], isNotEmpty);

      await signIn('a@mail.ru');
      final twice = await call(
        'POST',
        '/api/auth/register',
        body: {'name': 'Ещё', 'email': 'A@mail.ru ', 'password': 'secret123'},
      );
      expect(twice.status, 400);
      expect(twice.body['error'], contains('email'));
    });

    test('неверный пароль — 400, токен не выдаётся', () async {
      await signIn();
      final reply = await call(
        'POST',
        '/api/auth/login',
        body: {'email': 'user@mail.ru', 'password': 'wrong-pass'},
      );
      expect(reply.status, 400);
      expect(reply.body.containsKey('token'), isFalse);
    });

    test('без токена и с чужим токеном — 401', () async {
      expect((await call('GET', '/api/me')).status, 401);
      expect((await call('GET', '/api/me', token: 'abc')).status, 401);
      expect((await call('GET', '/api/notes')).status, 401);
    });

    test('после выхода токен больше не действует', () async {
      final token = await signIn();
      expect((await call('GET', '/api/me', token: token)).status, 200);
      final out = await call('POST', '/api/auth/logout', token: token);
      expect(out.status, 204);
      expect((await call('GET', '/api/me', token: token)).status, 401);
    });

    test('токен действует 30 дней', () async {
      var now = DateTime(2026, 10, 12);
      final timed = ApiServer(
        db: db,
        catalog: const [],
        hasher: fastHasher(),
        clock: () => now,
      );
      await call(
        'POST',
        '/api/auth/register',
        body: {'name': 'Алия', 'email': 'a@mail.ru', 'password': 'secret123'},
        to: timed,
      );
      final login = await call(
        'POST',
        '/api/auth/login',
        body: {'email': 'a@mail.ru', 'password': 'secret123'},
        to: timed,
      );
      final token = login.body['token'] as String;

      now = now.add(const Duration(days: 29));
      expect(
        (await call('GET', '/api/me', token: token, to: timed)).status,
        200,
      );
      now = now.add(const Duration(days: 2));
      final expired = await call('GET', '/api/me', token: token, to: timed);
      expect(expired.status, 401);
      expect(expired.body['error'], contains('войдите снова'));
    });

    test('в базе хранится хэш токена, а не сам токен', () async {
      final token = await signIn();
      final row = await db.select(db.apiTokens).getSingle();
      expect(row.tokenHash, isNot(token));
      expect(row.tokenHash, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('удаление аккаунта удаляет и токены', () async {
      final token = await signIn();
      final wrong = await call(
        'DELETE',
        '/api/me',
        body: {'password': 'wrong-pass'},
        token: token,
      );
      expect(wrong.status, 400);
      final ok = await call(
        'DELETE',
        '/api/me',
        body: {'password': 'secret123'},
        token: token,
      );
      expect(ok.status, 204);
      expect(await db.select(db.apiTokens).get(), isEmpty);
      expect((await call('GET', '/api/me', token: token)).status, 401);
    });
  });

  group('ошибки в запросе', () {
    late String token;
    setUp(() async => token = await signIn());

    test('тело не JSON — 400', () async {
      final reply = await call('POST', '/api/notes', raw: '{', token: token);
      expect(reply.status, 400);
      expect(reply.body['error'], 'Тело запроса должно быть объектом JSON');
    });

    test('нет обязательного поля или неверный тип — 400', () async {
      final missing = await call(
        'POST',
        '/api/notes',
        body: {'title': 'Без текста'},
        token: token,
      );
      expect(missing.status, 400);
      expect(missing.body['error'], contains('body'));

      final wrongType = await call(
        'PUT',
        '/api/me/reminder',
        body: {'enabled': 'да', 'hour': 9, 'minute': 0},
        token: token,
      );
      expect(wrongType.status, 400);
    });

    test('неверное время напоминания — 400', () async {
      final reply = await call(
        'PUT',
        '/api/me/reminder',
        body: {'enabled': true, 'hour': 25, 'minute': 0},
        token: token,
      );
      expect(reply.status, 400);
      expect(reply.body['error'], 'Неверное время напоминания');
    });

    test('сбой базы — 500 без подробностей, подробности в журнал', () async {
      final lines = <String>[];
      final failing = ApiServer(
        db: db,
        catalog: const [],
        hasher: fastHasher(),
        log: lines.add,
      );
      // Ломаем базу: без таблицы токенов любой запрос с токеном падает.
      await db.customStatement('DROP TABLE api_tokens');
      final reply = await call('GET', '/api/me', token: 'abc', to: failing);
      expect(reply.status, 500);
      expect(reply.body, {'error': 'Внутренняя ошибка сервера'});
      expect(lines.any((l) => l.startsWith('Ошибка сервера')), isTrue);
      // Строка журнала о самом запросе: метод, адрес и код ответа.
      expect(lines.last, contains('GET    /api/me  →  500'));
    });
  });

  group('заметки: полный CRUD через API', () {
    test('создание, получение, изменение и удаление', () async {
      final token = await signIn();
      final created = await call(
        'POST',
        '/api/notes',
        body: {'title': 'Конспект', 'body': 'Текст', 'topicId': 'py_basics'},
        token: token,
      );
      expect(created.status, 201);
      final id = created.body['id'] as int;

      final list = await call('GET', '/api/notes', token: token);
      expect(list.body, hasLength(1));
      final byTopic = await call(
        'GET',
        '/api/notes?topicId=other',
        token: token,
      );
      expect(byTopic.body, isEmpty);

      final updated = await call(
        'PUT',
        '/api/notes/$id',
        body: {'title': 'Конспект 2', 'body': 'Новый текст'},
        token: token,
      );
      expect(updated.status, 204);
      final one = await call('GET', '/api/notes/$id', token: token);
      expect(one.body['title'], 'Конспект 2');
      expect(one.body['body'], 'Новый текст');

      expect(
        (await call('DELETE', '/api/notes/$id', token: token)).status,
        204,
      );
      expect((await call('GET', '/api/notes/$id', token: token)).status, 404);
    });

    test('чужую заметку нельзя прочитать, изменить или удалить', () async {
      final owner = await signIn('owner@mail.ru');
      final other = await signIn('other@mail.ru');
      final created = await call(
        'POST',
        '/api/notes',
        body: {'title': 'Личное', 'body': 'Текст'},
        token: owner,
      );
      final id = created.body['id'];

      expect((await call('GET', '/api/notes/$id', token: other)).status, 404);
      final put = await call(
        'PUT',
        '/api/notes/$id',
        body: {'title': 'Взлом', 'body': 'Текст'},
        token: other,
      );
      expect(put.status, 404);
      expect(
        (await call('DELETE', '/api/notes/$id', token: other)).status,
        404,
      );
      expect((await call('GET', '/api/notes', token: other)).body, isEmpty);
      // У владельца заметка не изменилась.
      final mine = await call('GET', '/api/notes/$id', token: owner);
      expect(mine.body['title'], 'Личное');
    });
  });

  group('свои темы и избранное', () {
    test('CRUD своей темы и проверка длительности', () async {
      final token = await signIn();
      final fields = {
        'directionId': 'python',
        'title': 'Асинхронность',
        'description': 'asyncio',
        'minutes': 90,
        'category': 'Продвинутое',
        'prerequisites': <String>[],
      };
      final created = await call(
        'POST',
        '/api/custom-topics',
        body: fields,
        token: token,
      );
      expect(created.status, 201);
      final id = created.body['id'] as String;
      expect(id, startsWith('custom_'));

      final one = await call('GET', '/api/custom-topics/$id', token: token);
      expect(one.body['title'], 'Асинхронность');
      expect(one.body['directionId'], 'python');

      final tooShort = await call(
        'PUT',
        '/api/custom-topics/$id',
        body: {...fields, 'minutes': 10},
        token: token,
      );
      expect(tooShort.status, 400);

      final renamed = await call(
        'PUT',
        '/api/custom-topics/$id',
        body: {...fields, 'title': 'asyncio'},
        token: token,
      );
      expect(renamed.status, 204);
      final list = await call(
        'GET',
        '/api/custom-topics?directionId=python',
        token: token,
      );
      expect((list.body as List).single['title'], 'asyncio');

      final other = await signIn('other@mail.ru');
      expect(
        (await call('DELETE', '/api/custom-topics/$id', token: other)).status,
        404,
      );
      expect(
        (await call('DELETE', '/api/custom-topics/$id', token: token)).status,
        204,
      );
      expect(
        (await call('GET', '/api/custom-topics/$id', token: token)).status,
        404,
      );
    });

    test('избранное включается и выключается', () async {
      final token = await signIn();
      await call('POST', '/api/favorites/py_basics/toggle', token: token);
      expect((await call('GET', '/api/favorites', token: token)).body, [
        'py_basics',
      ]);
      await call('POST', '/api/favorites/py_basics/toggle', token: token);
      expect((await call('GET', '/api/favorites', token: token)).body, isEmpty);
    });
  });

  group('планы через клиент API', () {
    final today = DateTime(2026, 10, 12);
    final topics = [
      const Topic(id: 'dart', title: 'Dart', minutes: 60, category: 'Основы'),
      const Topic(
        id: 'widgets',
        title: 'Виджеты',
        minutes: 60,
        category: 'UI',
        prerequisites: ['dart'],
      ),
    ];
    final settings = ScheduleSettings(
      hoursPerWeek: 7,
      studyDays: const {1, 2, 3, 4, 5, 6, 7},
      startDate: today,
    );

    /// Клиент API с токеном пользователя [email], работающий с сервером
    /// в памяти, — так же приложение работает с настоящим сервером.
    Future<(ApiClient, int)> clientFor(String email) async {
      final token = await signIn(email);
      final me = await call('GET', '/api/me', token: token);
      final api = ApiClient(
        baseUrl: 'http://localhost',
        token: token,
        httpClient: inMemoryClient(server),
      );
      addTearDown(api.close);
      return (api, me.body['id'] as int);
    }

    test('план составляется в приложении и сохраняется на сервере', () async {
      final (api, userId) = await clientFor('user@mail.ru');
      final plans = ApiPlanRepository(api);
      final service = PlanService(plans, clock: () => today);

      final planId = await service.createPlan(
        userId: userId,
        directionId: 'flutter',
        title: 'Мой план',
        topics: topics,
        settings: settings,
        knownTopicIds: const {},
      );
      final active = await plans.watchActivePlan(userId).first;
      expect(active!.id, planId);
      expect(active.title, 'Мой план');
      expect((await plans.planTopics(planId)).map((t) => t.topicId), [
        'dart',
        'widgets',
      ]);

      // Отметка занятия попадает в историю.
      final sessions = await plans.sessions(planId);
      expect(sessions, isNotEmpty);
      await service.toggleSession(sessions.first);
      expect((await plans.sessionById(sessions.first.id))!.isDone, isTrue);
      expect(await plans.watchCompletedSessions(userId).first, hasLength(1));

      await plans.renamePlan(planId, 'Новое имя');
      expect((await plans.planById(planId))!.title, 'Новое имя');
      await plans.deletePlan(planId);
      expect(await plans.planById(planId), isNull);
    });

    test('чужой план для другого пользователя не существует', () async {
      final (ownerApi, ownerId) = await clientFor('owner@mail.ru');
      final planId =
          await PlanService(
            ApiPlanRepository(ownerApi),
            clock: () => today,
          ).createPlan(
            userId: ownerId,
            directionId: 'flutter',
            title: 'Личный план',
            topics: topics,
            settings: settings,
            knownTopicIds: const {},
          );
      final sessionId = (await ApiPlanRepository(ownerApi).sessions(planId))
          .first
          .id;

      final (otherApi, _) = await clientFor('other@mail.ru');
      final other = ApiPlanRepository(otherApi);
      expect(await other.planById(planId), isNull);
      expect(await other.sessionById(sessionId), isNull);
      await expectLater(
        other.deletePlan(planId),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'код', 404)),
      );
      // План владельца на месте.
      expect(await ApiPlanRepository(ownerApi).planById(planId), isNotNull);
    });

    test('пустые настройки расписания отклоняются', () async {
      final (api, userId) = await clientFor('user@mail.ru');
      final plans = ApiPlanRepository(api);
      final planId = await PlanService(plans, clock: () => today).createPlan(
        userId: userId,
        directionId: 'flutter',
        title: 'План',
        topics: topics,
        settings: settings,
        knownTopicIds: const {},
      );
      await expectLater(
        plans.updateSettings(
          planId,
          ScheduleSettings(
            hoursPerWeek: 5,
            studyDays: const {},
            startDate: today,
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'код', 400)
              .having((e) => e.message, 'текст', contains('дни занятий')),
        ),
      );
    });
  });

  group('Pomodoro', () {
    test('запись интервала и неверная длительность', () async {
      final token = await signIn();
      final ok = await call(
        'POST',
        '/api/pomodoros',
        body: {'minutes': 25, 'topicTitle': 'Dart'},
        token: token,
      );
      expect(ok.status, 201);
      final list = await call('GET', '/api/pomodoros', token: token);
      expect((list.body as List).single['minutes'], 25);
      final bad = await call(
        'POST',
        '/api/pomodoros',
        body: {'minutes': 0},
        token: token,
      );
      expect(bad.status, 400);
    });
  });
}
