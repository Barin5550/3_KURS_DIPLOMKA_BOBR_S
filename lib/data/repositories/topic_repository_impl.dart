// Репозиторий своих тем пользователя и избранного (слой data).
// Реализует интерфейс TopicRepository из слоя domain и хранит данные в
// таблицах custom_topics и favorites локальной базы SQLite (через drift).
// Создаётся в topicRepositoryProvider (presentation/providers/providers.dart),
// используется каталогом тем, карточкой темы и экраном создания своей темы.

import 'package:drift/drift.dart';

import '../../domain/entities/topic.dart';
import '../../domain/repositories/repositories.dart';
import '../db/app_database.dart';

/// Собственные темы пользователя и избранное.
///
/// Идентификатор своей темы имеет вид `custom_<id>`, чтобы не пересекаться
/// с идентификаторами тем каталога.
class TopicRepositoryImpl implements TopicRepository {
  /// Получает объект базы данных, общий для всего приложения.
  TopicRepositoryImpl(this._db);

  /// База данных приложения (таблицы описаны в data/db/app_database.dart).
  final AppDatabase _db;

  /// Приставка к id своих тем: `custom_5` — своя тема с id 5 в базе.
  static const customPrefix = 'custom_';

  /// `true`, если [topicId] принадлежит своей теме, а не теме каталога.
  static bool isCustomId(String topicId) => topicId.startsWith(customPrefix);

  /// Поток своих тем пользователя, новые сверху.
  ///
  /// Если указан [directionId], возвращаются только темы этого направления.
  @override
  Stream<List<Topic>> watchCustomTopics(int userId, {String? directionId}) {
    // SELECT из таблицы custom_topics.
    final query = _db.select(_db.customTopics)
      // Только темы этого пользователя...
      ..where((t) {
        final byUser = t.userId.equals(userId);
        // ...и, если направление задано, только этого направления.
        return directionId == null
            ? byUser
            : byUser & t.directionId.equals(directionId);
      })
      // Сначала самые новые темы.
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    // watch() присылает новый список при каждом изменении таблицы.
    return query.watch().map((rows) => rows.map(_toTopic).toList());
  }

  /// Свои темы пользователя в направлении (однократное чтение, без потока).
  @override
  Future<List<Topic>> customTopics(int userId, String directionId) async {
    // Выбираем строки по пользователю и направлению одновременно.
    final rows =
        await (_db.select(_db.customTopics)..where(
              (t) =>
                  t.userId.equals(userId) & t.directionId.equals(directionId),
            ))
            .get();
    // Строки базы превращаем в сущности Topic.
    return rows.map(_toTopic).toList();
  }

  /// Своя тема по строковому id вида `custom_<id>` или `null`.
  @override
  Future<Topic?> customTopicById(String topicId) async {
    // Достаём числовой id; у темы каталога его нет — сразу null.
    final id = _parseId(topicId);
    if (id == null) return null;
    // Ищем строку с этим id в таблице custom_topics.
    final row = await (_db.select(
      _db.customTopics,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toTopic(row);
  }

  /// Направление своей темы (для экрана карточки темы).
  Future<String?> directionOf(String topicId) async {
    // Для темы каталога направление здесь не хранится — возвращаем null.
    final id = _parseId(topicId);
    if (id == null) return null;
    // Читаем строку темы и берём из неё только id направления.
    final row = await (_db.select(
      _db.customTopics,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.directionId;
  }

  /// Создаёт свою тему и возвращает её строковый id `custom_<id>`.
  ///
  /// [prerequisites] — id тем, которые нужно изучить раньше этой.
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
    // INSERT в custom_topics; drift возвращает числовой id новой строки.
    final id = await _db
        .into(_db.customTopics)
        .insert(
          // Значения новой строки; текст очищается от пробелов по краям.
          CustomTopicsCompanion.insert(
            userId: userId,
            directionId: directionId,
            title: title.trim(),
            description: Value(description.trim()),
            minutes: minutes,
            category: category.trim(),
            // Список предшественников хранится одной строкой через запятую.
            prerequisites: Value(prerequisites.join(',')),
            createdAt: DateTime.now(),
          ),
        );
    // Добавляем приставку, чтобы id не совпал с темой каталога.
    return '$customPrefix$id';
  }

  /// Изменяет свою тему. Тему каталога менять нельзя — будет [AppException].
  @override
  Future<void> updateCustomTopic({
    required String topicId,
    required String title,
    required String description,
    required int minutes,
    required String category,
    required List<String> prerequisites,
  }) async {
    // Нет числового id — значит, это тема каталога, её менять запрещено.
    final id = _parseId(topicId);
    if (id == null) throw const AppException('Тему каталога нельзя изменить');
    // UPDATE custom_topics ... WHERE id = ? с новыми значениями полей.
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

  /// Удаляет свою тему и все отметки «избранное» для неё.
  @override
  Future<void> deleteCustomTopic(String topicId) async {
    // Тему каталога удалить нельзя.
    final id = _parseId(topicId);
    if (id == null) throw const AppException('Тему каталога нельзя удалить');
    // Транзакция: оба удаления выполняются вместе или не выполняются вовсе.
    await _db.transaction(() async {
      // Удаляем саму тему.
      await (_db.delete(_db.customTopics)..where((t) => t.id.equals(id))).go();
      // Удаляем её из избранного (там хранится строковый id темы).
      await (_db.delete(
        _db.favorites,
      )..where((f) => f.topicId.equals(topicId))).go();
    });
  }

  /// Поток id избранных тем пользователя (множество без повторов).
  @override
  Stream<Set<String>> watchFavorites(int userId) =>
      // SELECT из favorites для этого пользователя; watch() следит за
      // таблицей, а из каждой строки берём только id темы и собираем в Set.
      (_db.select(_db.favorites)..where((f) => f.userId.equals(userId)))
          .watch()
          .map((rows) => rows.map((r) => r.topicId).toSet());

  /// Добавляет тему в избранное или убирает, если она там уже есть.
  @override
  Future<void> toggleFavorite(int userId, String topicId) async {
    // Сначала пробуем удалить отметку; go() вернёт число удалённых строк.
    final deleted = await (_db.delete(
      _db.favorites,
    )..where((f) => f.userId.equals(userId) & f.topicId.equals(topicId))).go();
    // Ничего не удалилось — темы в избранном не было, добавляем её.
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

  /// Превращает `custom_5` в число 5. Для темы каталога возвращает `null`.
  int? _parseId(String topicId) => isCustomId(topicId)
      // Отрезаем приставку и пробуем прочитать остаток как число.
      ? int.tryParse(topicId.substring(customPrefix.length))
      : null;

  /// Переводит строку таблицы [CustomTopicRow] в сущность [Topic].
  Topic _toTopic(CustomTopicRow r) => Topic(
    // Строковый id с приставкой custom_.
    id: '$customPrefix${r.id}',
    title: r.title,
    description: r.description,
    minutes: r.minutes,
    category: r.category,
    // Своим темам всегда ставится уровень сложности 3 (в каталоге
    // встречаются уровни от 1 до 6).
    level: 3,
    // Строку «a,b,c» разбиваем обратно в список; пустая строка — пустой список.
    prerequisites: r.prerequisites.isEmpty
        ? const []
        : r.prerequisites.split(','),
    // Отметка, что тема создана пользователем, а не взята из каталога.
    isCustom: true,
  );
}
