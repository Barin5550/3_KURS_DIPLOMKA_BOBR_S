// Перевод сущностей приложения в JSON и обратно для обмена с сервером API.
// Слой: data. Этими функциями пользуются обе стороны: сервер (lib/server/)
// превращает данные из базы в JSON-ответ, а приложение (репозитории в
// lib/data/api/) разбирает ответ сервера обратно в сущности domain.
// Так формат данных описан в одном месте и не может разойтись.

import '../../domain/entities/note.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/schedule_settings.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/topic.dart';
import '../../domain/entities/user.dart';

/// JSON-объект: словарь «имя поля — значение».
typedef Json = Map<String, dynamic>;

/// Дата и время записываются строкой ISO 8601, например
/// `2026-10-15T09:30:00.000`.
String dateToJson(DateTime date) => date.toIso8601String();

/// Разбирает дату из строки ISO 8601.
DateTime dateFromJson(Object? value) => DateTime.parse(value as String);

/// То же для необязательной даты: `null` остаётся `null`.
DateTime? dateOrNullFromJson(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// Список строк из JSON (например, идентификаторы тем).
List<String> stringsFromJson(Object? value) =>
    (value as List<dynamic>? ?? const []).cast<String>();

/// Пользователь → JSON. Хэш пароля и соль сюда не попадают никогда.
Json userToJson(AppUser user) => {
  'id': user.id,
  'name': user.name,
  'email': user.email,
  'avatarColor': user.avatarColor,
  'createdAt': dateToJson(user.createdAt),
  'reminderEnabled': user.reminderEnabled,
  'reminderHour': user.reminderHour,
  'reminderMinute': user.reminderMinute,
};

/// JSON → пользователь.
AppUser userFromJson(Json json) => AppUser(
  id: json['id'] as int,
  name: json['name'] as String,
  email: json['email'] as String,
  avatarColor: json['avatarColor'] as int,
  createdAt: dateFromJson(json['createdAt']),
  reminderEnabled: json['reminderEnabled'] as bool,
  reminderHour: json['reminderHour'] as int,
  reminderMinute: json['reminderMinute'] as int,
);

/// Настройки расписания → JSON. Дни недели записываются по порядку.
Json settingsToJson(ScheduleSettings settings) => {
  'hoursPerWeek': settings.hoursPerWeek,
  'studyDays': settings.studyDays.toList()..sort(),
  'startDate': dateToJson(settings.startDate),
  'deadline': settings.deadline == null ? null : dateToJson(settings.deadline!),
};

/// JSON → настройки расписания.
ScheduleSettings settingsFromJson(Json json) => ScheduleSettings(
  // Число часов может прийти как целое (5) или дробное (4.5).
  hoursPerWeek: (json['hoursPerWeek'] as num).toDouble(),
  studyDays: (json['studyDays'] as List<dynamic>).cast<int>().toSet(),
  startDate: dateFromJson(json['startDate']),
  deadline: dateOrNullFromJson(json['deadline']),
);

/// План обучения → JSON (без тем и занятий: они запрашиваются отдельно).
Json planToJson(StudyPlan plan) => {
  'id': plan.id,
  'userId': plan.userId,
  'directionId': plan.directionId,
  'title': plan.title,
  'settings': settingsToJson(plan.settings),
  'knownTopicIds': plan.knownTopicIds.toList()..sort(),
  'isActive': plan.isActive,
  'createdAt': dateToJson(plan.createdAt),
};

/// JSON → план обучения.
StudyPlan planFromJson(Json json) => StudyPlan(
  id: json['id'] as int,
  userId: json['userId'] as int,
  directionId: json['directionId'] as String,
  title: json['title'] as String,
  settings: settingsFromJson(json['settings'] as Json),
  knownTopicIds: stringsFromJson(json['knownTopicIds']).toSet(),
  isActive: json['isActive'] as bool,
  createdAt: dateFromJson(json['createdAt']),
);

/// Тема → JSON. Ссылки на материалы и вопрос теста не передаются:
/// они есть только у тем каталога, а каталог приходит целиком.
Json topicToJson(Topic topic) => {
  'id': topic.id,
  'title': topic.title,
  'description': topic.description,
  'minutes': topic.minutes,
  'level': topic.level,
  'category': topic.category,
  'prerequisites': topic.prerequisites,
  'isCustom': topic.isCustom,
};

/// JSON → тема.
Topic topicFromJson(Json json) => Topic(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String? ?? '',
  minutes: json['minutes'] as int,
  level: json['level'] as int? ?? 1,
  category: json['category'] as String,
  prerequisites: stringsFromJson(json['prerequisites']),
  isCustom: json['isCustom'] as bool? ?? false,
);

/// Тема внутри плана → JSON.
Json planTopicToJson(PlanTopic topic) => {
  'topicId': topic.topicId,
  'title': topic.title,
  'category': topic.category,
  'minutes': topic.minutes,
  'level': topic.level,
  'prerequisites': topic.prerequisites,
  'position': topic.position,
};

/// JSON → тема внутри плана.
PlanTopic planTopicFromJson(Json json) => PlanTopic(
  topicId: json['topicId'] as String,
  title: json['title'] as String,
  category: json['category'] as String,
  minutes: json['minutes'] as int,
  level: json['level'] as int,
  prerequisites: stringsFromJson(json['prerequisites']),
  position: json['position'] as int,
);

/// Запланированное (ещё не сохранённое) занятие → JSON.
Json plannedSessionToJson(PlannedSession session) => {
  'topicId': session.topicId,
  'topicTitle': session.topicTitle,
  'category': session.category,
  'date': dateToJson(session.date),
  'minutes': session.minutes,
  'kind': session.kind.name,
  'part': session.part,
  'totalParts': session.totalParts,
};

/// JSON → запланированное занятие.
PlannedSession plannedSessionFromJson(Json json) => PlannedSession(
  topicId: json['topicId'] as String,
  topicTitle: json['topicTitle'] as String,
  category: json['category'] as String,
  date: dateFromJson(json['date']),
  minutes: json['minutes'] as int,
  kind: SessionKind.fromName(json['kind'] as String),
  part: json['part'] as int? ?? 1,
  totalParts: json['totalParts'] as int? ?? 1,
);

/// Сохранённое занятие → JSON.
Json studySessionToJson(StudySession session) => {
  'id': session.id,
  'planId': session.planId,
  'topicId': session.topicId,
  'topicTitle': session.topicTitle,
  'category': session.category,
  'date': dateToJson(session.date),
  'minutes': session.minutes,
  'kind': session.kind.name,
  'part': session.part,
  'totalParts': session.totalParts,
  'isDone': session.isDone,
  'completedAt': session.completedAt == null
      ? null
      : dateToJson(session.completedAt!),
};

/// JSON → сохранённое занятие.
StudySession studySessionFromJson(Json json) => StudySession(
  id: json['id'] as int,
  planId: json['planId'] as int,
  topicId: json['topicId'] as String,
  topicTitle: json['topicTitle'] as String,
  category: json['category'] as String,
  date: dateFromJson(json['date']),
  minutes: json['minutes'] as int,
  kind: SessionKind.fromName(json['kind'] as String),
  part: json['part'] as int,
  totalParts: json['totalParts'] as int,
  isDone: json['isDone'] as bool,
  completedAt: dateOrNullFromJson(json['completedAt']),
);

/// Заметка → JSON.
Json noteToJson(Note note) => {
  'id': note.id,
  'userId': note.userId,
  'title': note.title,
  'body': note.body,
  'topicId': note.topicId,
  'topicTitle': note.topicTitle,
  'createdAt': dateToJson(note.createdAt),
  'updatedAt': dateToJson(note.updatedAt),
};

/// JSON → заметка.
Note noteFromJson(Json json) => Note(
  id: json['id'] as int,
  userId: json['userId'] as int,
  title: json['title'] as String,
  body: json['body'] as String,
  topicId: json['topicId'] as String?,
  topicTitle: json['topicTitle'] as String?,
  createdAt: dateFromJson(json['createdAt']),
  updatedAt: dateFromJson(json['updatedAt']),
);

/// Запись о завершённом «помидоре» → JSON.
Json pomodoroToJson(PomodoroEntry entry) => {
  'id': entry.id,
  'minutes': entry.minutes,
  'completedAt': dateToJson(entry.completedAt),
  'topicTitle': entry.topicTitle,
};

/// JSON → запись о «помидоре».
PomodoroEntry pomodoroFromJson(Json json) => PomodoroEntry(
  id: json['id'] as int,
  minutes: json['minutes'] as int,
  completedAt: dateFromJson(json['completedAt']),
  topicTitle: json['topicTitle'] as String?,
);
