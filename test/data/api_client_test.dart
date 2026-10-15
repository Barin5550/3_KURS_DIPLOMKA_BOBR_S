import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marshrut/data/api/api_client.dart';
import 'package:marshrut/domain/repositories/repositories.dart';

/// Тесты клиента API: адрес сервера, заголовки, разбор ответов и то,
/// какие сообщения увидит пользователь при ошибках сети и сервера.
void main() {
  /// Ответ JSON с кодом [status].
  http.Response json(Object? body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  /// Клиент API, запросы которого обрабатывает функция [handler].
  ApiClient client(
    MockClientHandler handler, {
    String baseUrl = 'http://192.168.1.5:8080',
    Duration timeout = const Duration(seconds: 10),
  }) {
    final api = ApiClient(
      baseUrl: baseUrl,
      httpClient: MockClient(handler),
      timeout: timeout,
    );
    addTearDown(api.close);
    return api;
  }

  group('адрес сервера', () {
    test('пробелы, косая черта и схема', () {
      expect(
        ApiClient.normalizeUrl(' 192.168.1.5:8080/ '),
        'http://192.168.1.5:8080',
      );
      expect(
        ApiClient.normalizeUrl('https://server.kz//'),
        'https://server.kz',
      );
      expect(ApiClient.normalizeUrl(''), '');
    });

    test('пустой адрес — понятная ошибка без запроса в сеть', () async {
      var sent = false;
      final api = client((_) async {
        sent = true;
        return json({});
      }, baseUrl: '');
      await expectLater(
        api.get('/api/health'),
        throwsA(
          isA<ConnectionException>().having(
            (e) => e.message,
            'текст',
            contains('Неверный адрес сервера'),
          ),
        ),
      );
      expect(sent, isFalse);
    });
  });

  group('запросы', () {
    test('токен, JSON и параметры запроса', () async {
      late http.Request seen;
      final api = client((request) async {
        seen = request;
        return json({'id': 7}, 201);
      })..token = 'abc';
      final reply = await api.post('/api/notes', {'title': 'Тема'});
      expect(reply, {'id': 7});
      expect(seen.method, 'POST');
      expect(seen.url.toString(), 'http://192.168.1.5:8080/api/notes');
      expect(seen.headers['Authorization'], 'Bearer abc');
      expect(jsonDecode(seen.body), {'title': 'Тема'});

      await api.get('/api/notes', query: {'topicId': 'py basics'});
      expect(seen.url.queryParameters, {'topicId': 'py basics'});
      expect(seen.body, isEmpty);
    });

    test('ответ 204 без тела — null', () async {
      final api = client((_) async => http.Response('', 204));
      expect(await api.delete('/api/notes/1'), isNull);
    });

    test('кириллица в ответе не портится', () async {
      final api = client((_) async => json({'title': 'Основы Python'}));
      expect(await api.get('/api/x'), {'title': 'Основы Python'});
    });

    test('проверка связи узнаёт сервер «Маршрута»', () async {
      await client((_) async => json({'status': 'ok', 'service': 'Маршрут'}))
          .checkHealth();
      await expectLater(
        client((_) async => json({'status': 'ok'})).checkHealth(),
        throwsA(isA<ConnectionException>()),
      );
    });
  });

  group('ошибки', () {
    test('текст ошибки сервера доходит до пользователя', () async {
      final api = client(
        (_) async =>
            json({'error': 'Пользователь с таким email уже есть'}, 400),
      );
      await expectLater(
        api.post('/api/auth/register', {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'код', 400)
              .having((e) => e.message, 'текст', contains('email')),
        ),
      );
    });

    test('500 без текста — общее сообщение с кодом', () async {
      final api = client((_) async => http.Response('', 500));
      await expectLater(
        api.get('/api/plans'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'текст',
            'Ошибка сервера (код 500)',
          ),
        ),
      );
    });

    test('ответ не JSON', () async {
      final api = client((_) async => http.Response('<html>', 200));
      await expectLater(
        api.get('/api/plans'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'текст',
            contains('не в формате JSON'),
          ),
        ),
      );
    });

    test('401 сообщает приложению, что нужно войти заново', () async {
      var calls = 0;
      final api = client((_) async => json({'error': 'Сессия истекла'}, 401))
        ..onUnauthorized = () => calls++;
      await expectLater(api.get('/api/me'), throwsA(isA<ApiException>()));
      expect(calls, 1);
    });

    test('нет связи с сервером', () async {
      final api = client((_) async => throw http.ClientException('refused'));
      await expectLater(
        api.get('/api/plans'),
        throwsA(
          isA<ConnectionException>().having(
            (e) => e.message,
            'текст',
            contains('той же сети Wi-Fi'),
          ),
        ),
      );
    });

    test('сервер не ответил вовремя', () async {
      final api = client(
        (_) => Completer<http.Response>().future,
        timeout: const Duration(milliseconds: 50),
      );
      await expectLater(
        api.get('/api/plans'),
        throwsA(
          isA<ConnectionException>().having(
            (e) => e.message,
            'текст',
            contains('не отвечает'),
          ),
        ),
      );
    });
  });

  group('самообновляющийся поток', () {
    test('перезагружается после изменения данных', () async {
      var notes = 0;
      final api = client((request) async {
        if (request.method == 'POST') {
          notes++;
          return json({'id': notes}, 201);
        }
        return json(notes);
      });
      final values = <Object?>[];
      final sub = api.watch(() => api.get('/api/notes')).listen(values.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(values, [0]);

      await api.post('/api/notes', {});
      await pumpEventQueue();
      expect(values, [0, 1]);
    });

    test('после ошибки показывает её и пробует снова', () async {
      var fail = true;
      final api = client(
        (_) async => fail ? http.Response('', 500) : json('ok'),
      );
      final values = <Object?>[];
      final errors = <Object>[];
      final sub = api
          .watch(
            () => api.get('/api/x'),
            retryDelay: const Duration(milliseconds: 20),
          )
          .listen(values.add, onError: errors.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(errors.single, isA<ApiException>());

      fail = false;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(values, ['ok']);
    });
  });
}
