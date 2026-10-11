import 'package:drift/drift.dart';

import '../../domain/entities/topic.dart';
import '../../domain/repositories/repositories.dart';
import '../db/app_database.dart';

/// Собственные темы пользователя и избранное.
///
/// Идентификатор своей темы имеет вид `custom_<id>`, чтобы не пересекаться
/// с идентификаторами тем каталога.
class TopicRepositoryImpl implements TopicRepository {
  TopicRepositoryImpl(this._db);

  final AppDatabase _db;

  static const customPrefix = 'custom_';

  static bool isCustomId(String topicId) => topicId.startsWith(customPrefix);

  @override
  Stream<List<Topic>> watchCustomTopics(int userId, {String? directionId}) {
    final query = _db.select(_db.customTopics)
      ..where((t) {
        final byUser = t.userId.equals(userId);
        return directionId == null
            ? byUser
            : byUser & t.directionId.equals(directionId);
      })
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toTopic).toList());
  }

  @override
  Future<List<Topic>> customTopics(int userId, String directionId) async {
    final rows =
        await (_db.select(_db.customTopics)..where(
              (t) =>
                  t.userId.equals(userId) & t.directionId.equals(directionId),
            ))
            .get();
    return rows.map(_toTopic).toList();
  }

  @override
  Future<Topic?> customTopicById(String topicId) async {
    final id = _parseId(topicId);
    if (id == null) return null;
    final row = await (_db.select(
      _db.customTopics,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toTopic(row);
  }

  /// Направление своей темы (для экрана карточки темы).
  Future<String?> directionOf(String topicId) async {
    final id = _parseId(topicId);
    if (id == null) return null;
    final row = await (_db.select(
      _db.customTopics,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.directionId;
  }

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
    final id = await _db
        .into(_db.customTopics)
        .insert(
          CustomTopicsCompanion.insert(
            userId: userId,
            directionId: directionId,
            title: title.trim(),
            description: Value(description.trim()),
            minutes: minutes,
            category: category.trim(),
            prerequisites: Value(prerequisites.join(',')),
            createdAt: DateTime.now(),
          ),
        );
    return '$customPrefix$id';
  }

  @override
  Future<void> updateCustomTopic({
    required String topicId,
    required String title,
    required String description,
    required int minutes,
    required String category,
    required List<String> prerequisites,
  }) async {
    final id = _parseId(topicId);
    if (id == null) throw const AppException('Тему каталога нельзя изменить');
    await (_db.update(_db.customTopics)..where((t) => t.id.equals(id))).write(
      CustomTopicsCompanion(
        title: Value(title.trim()),
        description: Value(description.trim()),
        minutes: Value(minutes),
        category: Value(category.trim()),
        prerequisites: Value(prerequisites.join(',')),
      ),
    );
  }

  @override
  Future<void> deleteCustomTopic(String topicId) async {
    final id = _parseId(topicId);
    if (id == null) throw const AppException('Тему каталога нельзя удалить');
    await _db.transaction(() async {
      await (_db.delete(_db.customTopics)..where((t) => t.id.equals(id))).go();
      await (_db.delete(
        _db.favorites,
      )..where((f) => f.topicId.equals(topicId))).go();
    });
  }

  @override
  Stream<Set<String>> watchFavorites(int userId) =>
      (_db.select(_db.favorites)..where((f) => f.userId.equals(userId)))
          .watch()
          .map((rows) => rows.map((r) => r.topicId).toSet());

  @override
  Future<void> toggleFavorite(int userId, String topicId) async {
    final deleted = await (_db.delete(
      _db.favorites,
    )..where((f) => f.userId.equals(userId) & f.topicId.equals(topicId))).go();
    if (deleted == 0) {
      await _db
          .into(_db.favorites)
          .insert(
            FavoritesCompanion.insert(
              userId: userId,
              topicId: topicId,
              createdAt: DateTime.now(),
            ),
          );
    }
  }

  int? _parseId(String topicId) => isCustomId(topicId)
      ? int.tryParse(topicId.substring(customPrefix.length))
      : null;

  Topic _toTopic(CustomTopicRow r) => Topic(
    id: '$customPrefix${r.id}',
    title: r.title,
    description: r.description,
    minutes: r.minutes,
    category: r.category,
    level: 3,
    prerequisites: r.prerequisites.isEmpty
        ? const []
        : r.prerequisites.split(','),
    isCustom: true,
  );
}
