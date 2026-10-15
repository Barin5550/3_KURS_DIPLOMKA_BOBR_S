// Клиент HTTP для сервера API «Маршрута».
// Слой: data. Через этот класс проходят все запросы приложения к данным:
// он добавляет к запросу токен входа, переводит тело в JSON, ждёт ответ
// не дольше заданного времени и превращает ошибки (нет сети, сервер не
// отвечает, ошибка 4xx/5xx) в понятные сообщения на русском.
// Им пользуются репозитории в этой же папке (api_*_repository.dart);
// создаёт его apiClientProvider в presentation/providers/providers.dart.

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/repositories/repositories.dart';

/// Ошибка, которую вернул сервер (код ответа 4xx или 5xx).
class ApiException extends AppException {
  /// [statusCode] — код ответа HTTP, [message] — текст для пользователя.
  const ApiException(this.statusCode, super.message);

  /// Код ответа HTTP, например 400, 401, 404 или 500.
  final int statusCode;
}

/// Клиент API: отправляет запросы и разбирает ответы сервера.
class ApiClient {
  /// [baseUrl] — адрес сервера, например `http://192.168.1.5:8080`;
  /// [token] — токен входа, если пользователь уже вошёл;
  /// [httpClient] можно подменить в тестах;
  /// [timeout] — сколько ждать ответа сервера.
  ApiClient({
    required String baseUrl,
    this.token,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 10),
  }) : _baseUrl = normalizeUrl(baseUrl),
       _ownsHttp = httpClient == null,
       _http = httpClient ?? http.Client();

  /// Объект пакета http, который физически отправляет запросы.
  final http.Client _http;

  /// true, если объект http создан этим клиентом (тогда его закрывает
  /// [close]); переданный снаружи объект закрывает его владелец.
  final bool _ownsHttp;

  /// Предельное время ожидания ответа.
  final Duration timeout;

  /// Адрес сервера без косой черты в конце.
  String _baseUrl;

  /// Токен входа: отправляется в заголовке `Authorization`.
  String? token;

  /// Вызывается, когда сервер ответил 401 («нужно войти»): так приложение
  /// узнаёт, что токен устарел, и возвращает пользователя на экран входа.
  void Function()? onUnauthorized;

  /// Сигнал «данные на сервере изменились»: после каждого успешного запроса
  /// на изменение (POST, PUT, PATCH, DELETE) сюда приходит событие, и
  /// открытые экраны заново загружают свои данные.
  final _changes = StreamController<void>.broadcast();

  /// Поток событий об изменении данных.
  Stream<void> get changes => _changes.stream;

  /// Текущий адрес сервера.
  String get baseUrl => _baseUrl;

  /// Меняет адрес сервера (например, после правки в настройках входа).
  set baseUrl(String value) => _baseUrl = normalizeUrl(value);

  /// Приводит адрес к виду `http://хост:порт`: убирает пробелы и косую
  /// черту в конце, а если схема не указана — добавляет `http://`.
  static String normalizeUrl(String url) {
    // Убираем пробелы по краям и косые черты в конце адреса.
    var result = url.trim().replaceAll(RegExp(r'/+$'), '');
    // Пользователь мог ввести просто «192.168.1.5:8080».
    if (result.isNotEmpty && !result.contains('://')) {
      result = 'http://$result';
    }
    return result;
  }

  /// GET-запрос: получение данных.
  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  /// POST-запрос: создание записи или действие.
  Future<dynamic> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  /// PUT-запрос: изменение записи целиком.
  Future<dynamic> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  /// PATCH-запрос: изменение части записи.
  Future<dynamic> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  /// DELETE-запрос: удаление записи.
  Future<dynamic> delete(String path, [Object? body]) =>
      _send('DELETE', path, body: body);

  /// Отправляет запрос и возвращает разобранный JSON ответа
  /// (`null`, если у ответа нет тела, например код 204).
  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    // Собираем полный адрес: сервер + путь + параметры запроса.
    final Uri uri;
    try {
      uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    } on FormatException {
      throw ConnectionException('Неверный адрес сервера: $_baseUrl');
    }
    // Адрес без хоста (например, пустой) отправить нельзя.
    if (!uri.hasAuthority || !uri.scheme.startsWith('http')) {
      throw ConnectionException(
        'Неверный адрес сервера: «$_baseUrl». Пример: http://192.168.1.5:8080',
      );
    }
    // Готовим запрос: метод, адрес, заголовки и тело в JSON.
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    // Токен входа передаётся в стандартном заголовке Authorization.
    final currentToken = token;
    if (currentToken != null) {
      request.headers['Authorization'] = 'Bearer $currentToken';
    }
    // Тело есть только у запросов с данными.
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      // Отправляем запрос и ждём ответ не дольше timeout.
      final streamed = await _http.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed).timeout(timeout);
    } on TimeoutException {
      throw ConnectionException(
        'Сервер $_baseUrl не отвечает. Проверьте, что сервер запущен.',
      );
    } on http.ClientException {
      // Нет сети, сервер выключен или адрес неверный.
      throw ConnectionException(
        'Нет связи с сервером $_baseUrl. Проверьте, что сервер запущен и '
        'телефон в той же сети Wi-Fi.',
      );
    }

    // Разбираем тело ответа (оно в UTF-8, чтобы не испортить кириллицу).
    final text = utf8.decode(response.bodyBytes);
    final Object? data;
    try {
      data = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      throw ApiException(
        response.statusCode,
        'Сервер вернул ответ не в формате JSON (код ${response.statusCode})',
      );
    }

    // Успешный ответ (коды 200–299).
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Запрос на изменение прошёл — сообщаем экранам, что данные другие.
      if (method != 'GET') _changes.add(null);
      return data;
    }
    // Текст ошибки сервер присылает в поле error.
    final message = data is Map && data['error'] is String
        ? data['error'] as String
        : 'Ошибка сервера (код ${response.statusCode})';
    // 401 — токен недействителен: просим войти заново.
    if (response.statusCode == 401) onUnauthorized?.call();
    throw ApiException(response.statusCode, message);
  }

  /// GET /api/health — проверяет, что по адресу [baseUrl] отвечает именно
  /// сервер «Маршрута». При ошибке выбрасывает [AppException] с причиной.
  Future<void> checkHealth() async {
    final data = await get('/api/health');
    if (data is! Map || data['service'] != 'Маршрут') {
      throw const ConnectionException(
        'По этому адресу отвечает не сервер «Маршрута»',
      );
    }
  }

  /// Поток данных, который обновляется сам: сразу загружает значение через
  /// [load], а потом загружает заново после каждого изменения данных
  /// (событие из [changes]). Если загрузка не удалась, поток передаёт
  /// ошибку экрану и через [retryDelay] пробует ещё раз.
  Stream<T> watch<T>(
    Future<T> Function() load, {
    Duration retryDelay = const Duration(seconds: 5),
  }) {
    // Поток, который получит экран.
    late final StreamController<T> controller;
    // Подписка на события об изменении данных.
    StreamSubscription<void>? subscription;
    // Таймер повторной попытки после ошибки.
    Timer? retry;
    // Номер последнего запроса: ответ на устаревший запрос отбрасывается.
    var generation = 0;
    // true, когда экран закрыт и данные больше не нужны.
    var cancelled = false;

    // Загружает данные и передаёт их в поток.
    Future<void> refresh() async {
      retry?.cancel();
      final current = ++generation;
      try {
        final value = await load();
        // Пока ждали ответ, мог уйти более новый запрос или экран закрылся.
        if (current == generation && !cancelled) controller.add(value);
      } on Object catch (error, stack) {
        if (current != generation || cancelled) return;
        // Показываем ошибку и через несколько секунд пробуем снова.
        controller.addError(error, stack);
        retry = Timer(retryDelay, refresh);
      }
    }

    controller = StreamController<T>(
      // Экран подписался: следим за изменениями и загружаем данные.
      onListen: () {
        subscription = changes.listen((_) => refresh());
        refresh();
      },
      // Экран закрыт: отписываемся и отменяем повтор.
      onCancel: () async {
        cancelled = true;
        retry?.cancel();
        await subscription?.cancel();
      },
    );
    return controller.stream;
  }

  /// Закрывает соединения (при завершении работы).
  void close() {
    if (_ownsHttp) _http.close();
    _changes.close();
  }
}
