// Свои темы пользователя и избранное через API.
// Слой: data. Реализует интерфейс TopicRepository запросами к серверу
// (адреса /api/custom-topics и /api/favorites). Создание, чтение,
// изменение и удаление своих тем — один из примеров CRUD через API.

import '../../domain/entities/topic.dart';
import '../../domain/repositories/repositories.dart';
import 'api_client.dart';
import 'api_json.dart';

/// Репозиторий своих тем и избранного, работающий через сервер API.
class ApiTopicRepository implements TopicRepository {
  /// [api] — клиент, через который идут запросы.
  ApiTopicRepository(this._api);

  /// Клиент API.
  final ApiClient _api;

  /// id своей темы начинается с `custom_` (например, `custom_12`); у тем
  /// каталога такого префикса нет, и на сервере их искать не нужно.
  static bool isCustomId(String topicId) => topicId.startsWith('custom_');

  /// GET /api/custom-topics?directionId=... — список своих тем.
  Future<List<Topic>> _load(String? directionId) async {
    final data = await _api.get(
      '/api/custom-topics',
      query: directionId == null ? null : {'directionId': directionId},
    );
    return (data as List<dynamic>).cast<Json>().map(topicFromJson).toList();
  }

  /// Поток своих тем (все или одного направления).
  @override
  Stream<List<Topic>> watchCustomTopics(int userId, {String? directionId}) =>
      _api.watch(() => _load(directionId));

  /// Свои темы направления (однократно).
  @override
  Future<List<Topic>> customTopics(int userId, String directionId) =>
      _load(directionId);

  /// GET /api/custom-topics/{id} вместе с направлением темы; `null` для
  /// темы каталога или если тема не найдена.
  Future<Json?> _get(String topicId) async {
    if (!isCustomId(topicId)) return null;
    try {
      return await _api.get('/api/custom-topics/$topicId') as Json;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Своя тема по id.
  @override
  Future<Topic?> customTopicById(String topicId) async {
    final data = await _get(topicId);
    return data == null ? null : topicFromJson(data);
  }

  /// Направление своей темы.
  @override
  Future<String?> directionOf(String topicId) async =>
      (await _get(topicId))?['directionId'] as String?;

  /// POST /api/custom-topics — новая тема; возвращает её id.
  @override
  Future<String> createCustomTopic({
    required int userId,
    required String directionId,
    required String title,
    required String description,
    required int minutes,
    required String category,
    required List<String> prerequisites,
  }) async {
    final data = await _api.post('/api/custom-topics', {
      'directionId': directionId,
      'title': title,
      'description': description,
      'minutes': minutes,
      'category': category,
      'prerequisites': prerequisites,
    }) as Json;
    return data['id'] as String;
  }

  /// PUT /api/custom-topics/{id} — изменение темы.
  @override
  Future<void> updateCustomTopic({
    required String topicId,
    required String title,
    required String description,
    required int minutes,
    required String category,
    required List<String> prerequisites,
  }) async {
    // Тему каталога изменить нельзя — как и в версии с локальной базой.
    if (!isCustomId(topicId)) {
      throw const AppException('Тему каталога нельзя изменить');
    }
    await _api.put('/api/custom-topics/$topicId', {
      'title': title,
      'description': description,
      'minutes': minutes,
      'category': category,
      'prerequisites': prerequisites,
    });
  }

  /// DELETE /api/custom-topics/{id} — удаление темы.
  @override
  Future<void> deleteCustomTopic(String topicId) async {
    if (!isCustomId(topicId)) {
      throw const AppException('Тему каталога нельзя удалить');
    }
    await _api.delete('/api/custom-topics/$topicId');
  }

  /// GET /api/favorites — поток id избранных тем.
  @override
  Stream<Set<String>> watchFavorites(int userId) => _api.watch(
    () async => (await _api.get('/api/favorites') as List<dynamic>)
        .cast<String>()
        .toSet(),
  );

  /// POST /api/favorites/{id}/toggle — добавить в избранное или убрать.
  @override
  Future<void> toggleFavorite(int userId, String topicId) =>
      _api.post('/api/favorites/${Uri.encodeComponent(topicId)}/toggle');
}
