// Интерфейсы репозиториев слоя domain.
//
// Слой domain описывает, ЧТО нужно приложению, а слой data решает, КАК это
// хранить (drift, JSON, shared_preferences). Благодаря этому логику можно
// тестировать с подменёнными реализациями.
// У каждого интерфейса данных две реализации:
// - lib/data/api — в приложении: запросы к серверу API по HTTP;
// - lib/data/repositories и lib/data/datasources — на сервере: база SQLite
//   и файлы каталога.
// Приложение связывает интерфейсы с реализациями API в presentation/providers.

import '../entities/direction.dart';
import '../entities/note.dart';
import '../entities/plan.dart';
import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import '../entities/user.dart';

/// Ошибка, понятная пользователю (выводится в интерфейсе как есть).
class AppException implements Exception {
  /// Создаёт ошибку с текстом [message].
  const AppException(this.message);

  /// Текст ошибки на русском языке, который увидит пользователь.
  final String message;

  /// При превращении в строку возвращается только текст ошибки.
  @override
  String toString() => message;
}

/// Каталог направлений обучения (готовые графы тем).
///
/// `abstract interface class` — интерфейс: только список методов без кода.
/// Реализация — CatalogRepositoryImpl (читает JSON-файлы из assets).
abstract interface class CatalogRepository {
  /// Загружает все направления вместе с их темами.
  Future<List<Direction>> loadDirections();
}

/// Учётные записи: регистрация, вход, профиль, пароль, напоминания.
/// Реализация — AuthRepositoryImpl (база данных drift).
abstract interface class AuthRepository {
  /// Регистрирует пользователя. Бросает [AppException], если email занят.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  /// Проверяет email и пароль. Бросает [AppException] при ошибке входа.
  Future<AppUser> login({required String email, required String password});

  /// Находит пользователя по [id]; `null`, если такого нет.
  Future<AppUser?> userById(int id);

  /// Сохраняет новые имя, email и цвет аватара; возвращает обновлённого
  /// пользователя.
  Future<AppUser> updateProfile({
    required int userId,
    required String name,
    required String email,
    required int avatarColor,
  });

  /// Меняет пароль: [oldPassword] нужен для проверки, [newPassword] —
  /// новый пароль. При ошибке бросает [AppException].
  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  });

  /// Удаляет аккаунт и все данные пользователя после проверки пароля.
  Future<void> deleteAccount({required int userId, required String password});

  /// Сохраняет настройку ежедневного напоминания: включено ли оно
  /// ([enabled]) и время [hour]:[minute]. Возвращает обновлённого
  /// пользователя.
  Future<AppUser> updateReminder({
    required int userId,
    required bool enabled,
    required int hour,
    required int minute,
  });
}

/// Хранение текущей сессии и настроек интерфейса.
/// Реализация — SessionStorageImpl (shared_preferences).
abstract interface class SessionStorage {
  /// id вошедшего пользователя или `null`, если никто не вошёл.
  int? get currentUserId;

  /// Запоминает id вошедшего пользователя (`null` — «никто не вошёл»).
  Future<void> saveCurrentUserId(int? userId);

  /// Сохранённая тема оформления (строка с названием режима).
  String get themeMode;

  /// Запоминает выбранную тему оформления.
  Future<void> saveThemeMode(String mode);
}

/// Хранилище планов, тем плана и занятий.
/// Реализация — PlanRepositoryImpl (база данных drift).
abstract interface class PlanRepository {
  /// Поток (Stream) списка планов пользователя. Stream присылает новое
  /// значение каждый раз, когда данные в базе меняются, поэтому экран,
  /// подписанный на него, обновляется сам.
  Stream<List<StudyPlan>> watchPlans(int userId);

  /// Поток с активным планом пользователя (`null`, если плана нет).
  Stream<StudyPlan?> watchActivePlan(int userId);

  /// Находит план по id; `null`, если не найден.
  Future<StudyPlan?> planById(int planId);

  /// Сохраняет новый план, его темы и занятия и делает его активным.
  Future<int> createPlan({
    required int userId,
    required String directionId,
    required String title,
    required ScheduleSettings settings,
    required Set<String> knownTopicIds,
    required List<Topic> orderedTopics,
    required List<PlannedSession> sessions,
  });

  /// Делает план [planId] активным у пользователя [userId].
  Future<void> setActive(int userId, int planId);

  /// Переименовывает план.
  Future<void> renamePlan(int planId, String title);

  /// Удаляет план вместе с его темами и занятиями.
  Future<void> deletePlan(int planId);

  /// Сохраняет новые настройки расписания плана.
  Future<void> updateSettings(int planId, ScheduleSettings settings);

  /// Темы плана — снимок, сохранённый вместе с планом.
  Future<List<PlanTopic>> planTopics(int planId);

  /// Заменяет список тем плана новым (в порядке изучения).
  Future<void> replacePlanTopics(int planId, List<Topic> orderedTopics);

  /// Поток со всеми занятиями плана.
  Stream<List<StudySession>> watchSessions(int planId);

  /// Все занятия плана — однократное чтение, без подписки на изменения.
  Future<List<StudySession>> sessions(int planId);

  /// Находит занятие по id; `null`, если не найдено.
  Future<StudySession?> sessionById(int sessionId);

  /// Ставит ([done] = true) или снимает отметку «выполнено» у занятия.
  Future<void> setSessionDone(int sessionId, {required bool done});

  /// Удаляет невыполненные занятия плана и сохраняет новые (перепланирование).
  Future<void> replaceOpenSessions(int planId, List<PlannedSession> sessions);

  /// Все выполненные занятия пользователя (для статистики и истории).
  Stream<List<StudySession>> watchCompletedSessions(int userId);
}

/// Собственные темы пользователя и избранное.
/// Реализация — TopicRepositoryImpl (база данных drift).
abstract interface class TopicRepository {
  /// Поток собственных тем пользователя; если указан [directionId] —
  /// только темы этого направления.
  Stream<List<Topic>> watchCustomTopics(int userId, {String? directionId});

  /// Собственные темы пользователя в направлении [directionId]
  /// (однократное чтение).
  Future<List<Topic>> customTopics(int userId, String directionId);

  /// Находит собственную тему по id; `null`, если не найдена.
  Future<Topic?> customTopicById(String topicId);

  /// Направление собственной темы [topicId]; `null` для темы каталога или
  /// если тема не найдена.
  Future<String?> directionOf(String topicId);

  /// Создаёт собственную тему и возвращает её id (строкой).
  Future<String> createCustomTopic({
    required int userId,
    required String directionId,
    required String title,
    required String description,
    required int minutes,
    required String category,
    required List<String> prerequisites,
  });

  /// Изменяет поля существующей собственной темы [topicId].
  Future<void> updateCustomTopic({
    required String topicId,
    required String title,
    required String description,
    required int minutes,
    required String category,
    required List<String> prerequisites,
  });

  /// Удаляет собственную тему.
  Future<void> deleteCustomTopic(String topicId);

  /// Поток множества id тем, которые пользователь добавил в избранное.
  Stream<Set<String>> watchFavorites(int userId);

  /// Добавляет тему в избранное или убирает её, если она уже там.
  Future<void> toggleFavorite(int userId, String topicId);
}

/// Заметки пользователя. Реализация — NoteRepositoryImpl (база drift).
abstract interface class NoteRepository {
  /// Поток заметок пользователя; если указан [topicId] — только заметки
  /// по этой теме.
  Stream<List<Note>> watchNotes(int userId, {String? topicId});

  /// Находит заметку по id; `null`, если не найдена.
  Future<Note?> noteById(int id);

  /// Создаёт заметку (её можно привязать к теме через [topicId] и
  /// [topicTitle]) и возвращает id новой заметки.
  Future<int> createNote({
    required int userId,
    required String title,
    required String body,
    String? topicId,
    String? topicTitle,
  });

  /// Сохраняет новые заголовок и текст заметки [id].
  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  });

  /// Удаляет заметку.
  Future<void> deleteNote(int id);
}

/// Журнал завершённых интервалов Pomodoro.
/// Реализация — PomodoroRepositoryImpl (база данных drift).
abstract interface class PomodoroRepository {
  /// Записывает завершённый интервал длиной [minutes] минут (и название
  /// темы, если она была указана).
  Future<void> logPomodoro({
    required int userId,
    required int minutes,
    String? topicTitle,
  });

  /// Поток записей Pomodoro пользователя.
  Stream<List<PomodoroEntry>> watchPomodoros(int userId);
}

/// Локальные уведомления (реализация зависит от платформы).
/// Реализации — LocalReminderService и пустая NoopReminderService.
abstract interface class ReminderService {
  /// Поддерживает ли платформа ежедневные напоминания по расписанию.
  bool get supportsDailyReminders;

  /// Подготавливает сервис уведомлений к работе.
  Future<void> init();

  /// Просит у пользователя разрешение на уведомления; `true`, если
  /// разрешение получено.
  Future<bool> requestPermission();

  /// Планирует ежедневное напоминание на время [hour]:[minute].
  Future<void> scheduleDailyReminder({required int hour, required int minute});

  /// Отменяет ежедневное напоминание.
  Future<void> cancelDailyReminder();

  /// Сразу показывает уведомление с заголовком [title] и текстом [body].
  Future<void> showNow({required String title, required String body});
}
