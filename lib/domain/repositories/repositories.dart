// Интерфейсы репозиториев слоя domain.
//
// Слой domain описывает, ЧТО нужно приложению, а слой data решает, КАК это
// хранить (drift, JSON, shared_preferences). Благодаря этому логику можно
// тестировать с подменёнными реализациями.

import '../entities/direction.dart';
import '../entities/note.dart';
import '../entities/plan.dart';
import '../entities/schedule_settings.dart';
import '../entities/session.dart';
import '../entities/topic.dart';
import '../entities/user.dart';

/// Ошибка, понятная пользователю (выводится в интерфейсе как есть).
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class CatalogRepository {
  Future<List<Direction>> loadDirections();
}

abstract interface class AuthRepository {
  /// Регистрирует пользователя. Бросает [AppException], если email занят.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  /// Проверяет email и пароль. Бросает [AppException] при ошибке входа.
  Future<AppUser> login({required String email, required String password});

  Future<AppUser?> userById(int id);

  Future<AppUser> updateProfile({
    required int userId,
    required String name,
    required String email,
    required int avatarColor,
  });

  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  });

  Future<AppUser> updateReminder({
    required int userId,
    required bool enabled,
    required int hour,
    required int minute,
  });
}

/// Хранение текущей сессии и настроек интерфейса.
abstract interface class SessionStorage {
  int? get currentUserId;
  Future<void> saveCurrentUserId(int? userId);
  String get themeMode;
  Future<void> saveThemeMode(String mode);
}

abstract interface class PlanRepository {
  Stream<List<StudyPlan>> watchPlans(int userId);
  Stream<StudyPlan?> watchActivePlan(int userId);
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

  Future<void> setActive(int userId, int planId);
  Future<void> renamePlan(int planId, String title);
  Future<void> deletePlan(int planId);
  Future<void> updateSettings(int planId, ScheduleSettings settings);

  Future<List<PlanTopic>> planTopics(int planId);
  Future<void> replacePlanTopics(int planId, List<Topic> orderedTopics);

  Stream<List<StudySession>> watchSessions(int planId);
  Future<List<StudySession>> sessions(int planId);
  Future<StudySession?> sessionById(int sessionId);
  Future<void> setSessionDone(int sessionId, {required bool done});

  /// Удаляет невыполненные занятия плана и сохраняет новые (перепланирование).
  Future<void> replaceOpenSessions(int planId, List<PlannedSession> sessions);

  /// Все выполненные занятия пользователя (для статистики и истории).
  Stream<List<StudySession>> watchCompletedSessions(int userId);
}

abstract interface class TopicRepository {
  Stream<List<Topic>> watchCustomTopics(int userId, {String? directionId});
  Future<List<Topic>> customTopics(int userId, String directionId);
  Future<Topic?> customTopicById(String topicId);
  Future<String> createCustomTopic({
    required int userId,
    required String directionId,
    required String title,
    required String description,
    required int minutes,
    required String category,
    required List<String> prerequisites,
  });
  Future<void> updateCustomTopic({
    required String topicId,
    required String title,
    required String description,
    required int minutes,
    required String category,
    required List<String> prerequisites,
  });
  Future<void> deleteCustomTopic(String topicId);

  Stream<Set<String>> watchFavorites(int userId);
  Future<void> toggleFavorite(int userId, String topicId);
}

abstract interface class NoteRepository {
  Stream<List<Note>> watchNotes(int userId, {String? topicId});
  Future<Note?> noteById(int id);
  Future<int> createNote({
    required int userId,
    required String title,
    required String body,
    String? topicId,
    String? topicTitle,
  });
  Future<void> updateNote({
    required int id,
    required String title,
    required String body,
  });
  Future<void> deleteNote(int id);
}

abstract interface class PomodoroRepository {
  Future<void> logPomodoro({
    required int userId,
    required int minutes,
    String? topicTitle,
  });
  Stream<List<PomodoroEntry>> watchPomodoros(int userId);
}

/// Локальные уведомления (реализация зависит от платформы).
abstract interface class ReminderService {
  /// Поддерживает ли платформа ежедневные напоминания по расписанию.
  bool get supportsDailyReminders;

  Future<void> init();
  Future<bool> requestPermission();
  Future<void> scheduleDailyReminder({required int hour, required int minute});
  Future<void> cancelDailyReminder();
  Future<void> showNow({required String title, required String body});
}
