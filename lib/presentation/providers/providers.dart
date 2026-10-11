// Все провайдеры Riverpod приложения в одном месте (слой presentation).
// Здесь собирается граф зависимостей: база данных → репозитории слоя data
// → сервисы → данные для экранов (планы, темы, заметки, тема оформления).
// Экраны получают данные только через эти провайдеры, а main() и тесты
// подставляют базу и настройки через overrides.

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/password_hasher.dart';
import '../../data/datasources/catalog_repository_impl.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../data/repositories/plan_repository_impl.dart';
import '../../data/repositories/session_storage_impl.dart';
import '../../data/repositories/topic_repository_impl.dart';
import '../../data/services/reminder_service_impl.dart';
import '../../domain/entities/direction.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/topic.dart';
import '../../domain/planner/dates.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/usecases/plan_service.dart';
import 'auth_controller.dart';

// Памятка по Riverpod (библиотека управления состоянием):
// * Provider — отдаёт готовый объект (репозиторий, сервис, значение);
// * FutureProvider — значение, которое вычисляется асинхронно (один раз);
// * StreamProvider — значение из потока, обновляется при новых данных;
// * NotifierProvider — изменяемое состояние с методами (контроллер);
// * .family — провайдер с параметром, например `directionProvider('id')`;
// * ref.watch — получить значение и пересчитаться, когда оно изменится;
// * ref.read — получить значение один раз, без подписки.

// -------------------------------------------------------------------------
// Внешние зависимости. Переопределяются в main() и в тестах через overrides.
// -------------------------------------------------------------------------

/// Открытая база данных SQLite. Создаётся в main() и подставляется через
/// `databaseProvider.overrideWithValue(...)`; без этого — ошибка.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider не переопределён'),
);

/// Хранилище простых настроек shared_preferences. Тоже подставляется
/// в main() (его открытие асинхронное, поэтому делается заранее).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider не переопределён'),
);

/// Сервис уведомлений. По умолчанию — настоящий, в тестах подменяется
/// на NoopReminderService.
final reminderServiceProvider = Provider<ReminderService>(
  (ref) => LocalReminderService(),
);

/// Источник текущего времени (в тестах подменяется фиксированной датой).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Сегодняшняя дата без времени суток (полночь), взятая из [clockProvider].
final todayProvider = Provider<DateTime>(
  (ref) => dateOnly(ref.watch(clockProvider)()),
);

// -------------------------------------------------------------------------
// Репозитории слоя data.
// -------------------------------------------------------------------------

/// Каталог направлений и тем. Читает JSON-файлы из ресурсов приложения
/// (rootBundle.loadString — чтение файла из папки assets).
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepositoryImpl(rootBundle.loadString),
);

/// Хэширование паролей (в тестах подменяется вариантом с малым числом
/// итераций, чтобы тесты шли быстро).
final passwordHasherProvider = Provider<PasswordHasher>(
  (ref) => PasswordHasher(),
);

/// Репозиторий пользователей: регистрация, вход, профиль.
/// Получает базу данных и объект для хэширования паролей.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.watch(databaseProvider),
    hasher: ref.watch(passwordHasherProvider),
  ),
);

/// Хранилище сессии («Запомнить меня») и темы оформления.
final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorageImpl(ref.watch(sharedPreferencesProvider)),
);

/// Репозиторий планов, тем плана и занятий.
final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepositoryImpl(ref.watch(databaseProvider)),
);

/// Репозиторий своих тем и избранного. Тип — сама реализация, а не
/// интерфейс: экранам нужен её дополнительный метод `directionOf`.
final topicRepositoryProvider = Provider<TopicRepositoryImpl>(
  (ref) => TopicRepositoryImpl(ref.watch(databaseProvider)),
);

/// Репозиторий заметок.
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(ref.watch(databaseProvider)),
);

/// Репозиторий журнала «помидоров» (Pomodoro).
final pomodoroRepositoryProvider = Provider<PomodoroRepository>(
  (ref) => PomodoroRepositoryImpl(ref.watch(databaseProvider)),
);

/// Сервис планов (domain/usecases/plan_service.dart): работает поверх
/// репозитория планов и использует общий источник времени.
final planServiceProvider = Provider<PlanService>(
  (ref) => PlanService(
    ref.watch(planRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

// -------------------------------------------------------------------------
// Пользователь.
// -------------------------------------------------------------------------

/// Состояние входа и действия с аккаунтом (см. auth_controller.dart).
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Id вошедшего пользователя или `null`.
///
/// select следит только за id: провайдеры ниже не пересчитываются,
/// если у пользователя поменялось, например, имя.
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.user?.id)),
);

// -------------------------------------------------------------------------
// Каталог.
// -------------------------------------------------------------------------

/// Все направления обучения из каталога (загружаются один раз).
final directionsProvider = FutureProvider<List<Direction>>(
  (ref) => ref.watch(catalogRepositoryProvider).loadDirections(),
);

/// Одно направление по id или `null`, если такого нет.
final directionProvider = FutureProvider.family<Direction?, String>((
  ref,
  id,
) async {
  // Ждём загрузки всего каталога...
  final directions = await ref.watch(directionsProvider.future);
  // ...и ищем в нём направление с нужным id.
  for (final d in directions) {
    if (d.id == id) return d;
  }
  return null;
});

/// Свои темы пользователя в направлении.
final customTopicsProvider = StreamProvider.family<List<Topic>, String?>((
  ref,
  directionId,
) {
  // Пока никто не вошёл — пустой список.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  // Иначе — поток своих тем из базы; null вместо направления — все темы.
  return ref
      .watch(topicRepositoryProvider)
      .watchCustomTopics(userId, directionId: directionId);
});

/// Темы направления: каталог + свои темы пользователя.
final directionTopicsProvider = FutureProvider.family<List<Topic>, String>((
  ref,
  directionId,
) async {
  // Темы направления из каталога и свои темы пользователя.
  final direction = await ref.watch(directionProvider(directionId).future);
  final custom = await ref.watch(customTopicsProvider(directionId).future);
  // Один общий список; «...?» пропускает темы, если направления нет.
  return [...?direction?.topics, ...custom];
});

/// Id тем, которые пользователь добавил в избранное.
final favoritesProvider = StreamProvider<Set<String>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const {});
  return ref.watch(topicRepositoryProvider).watchFavorites(userId);
});

// -------------------------------------------------------------------------
// Планы и занятия.
// -------------------------------------------------------------------------

/// Все планы вошедшего пользователя (обновляются при изменениях в базе).
final plansProvider = StreamProvider<List<StudyPlan>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(planRepositoryProvider).watchPlans(userId);
});

/// Активный план пользователя или `null`, если планов нет.
final activePlanProvider = StreamProvider<StudyPlan?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(planRepositoryProvider).watchActivePlan(userId);
});

/// Занятия плана с id [planId], по датам.
final planSessionsProvider = StreamProvider.family<List<StudySession>, int>(
  (ref, planId) => ref.watch(planRepositoryProvider).watchSessions(planId),
);

/// Прогресс плана (сколько выполнено), посчитанный по его занятиям.
///
/// AsyncValue — обёртка «загружается / ошибка / готово»; whenData
/// пересчитывает только готовое значение.
final planProgressProvider = Provider.family<AsyncValue<PlanProgress>, int>(
  (ref, planId) => ref
      .watch(planSessionsProvider(planId))
      .whenData((s) => PlanProgress.fromSessions(s, ref.watch(todayProvider))),
);

/// Все выполненные занятия пользователя (для статистики и истории).
final completedSessionsProvider = StreamProvider<List<StudySession>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(planRepositoryProvider).watchCompletedSessions(userId);
});

// -------------------------------------------------------------------------
// Заметки и Pomodoro.
// -------------------------------------------------------------------------

/// Заметки пользователя; если передан id темы — только по этой теме,
/// если `null` — все заметки.
final notesProvider = StreamProvider.family<List<Note>, String?>((
  ref,
  topicId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(noteRepositoryProvider).watchNotes(userId, topicId: topicId);
});

/// Журнал завершённых «помидоров» пользователя.
final pomodorosProvider = StreamProvider<List<PomodoroEntry>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(pomodoroRepositoryProvider).watchPomodoros(userId);
});

// -------------------------------------------------------------------------
// Тема оформления.
// -------------------------------------------------------------------------

/// Контроллер темы оформления: 'system', 'light' или 'dark'.
class ThemeModeController extends Notifier<String> {
  /// Начальное значение — тема, сохранённая в прошлый раз.
  @override
  String build() => ref.watch(sessionStorageProvider).themeMode;

  /// Меняет тему: сначала в состоянии (интерфейс перерисуется сразу),
  /// затем сохраняет выбор на устройстве.
  Future<void> set(String mode) async {
    state = mode;
    await ref.read(sessionStorageProvider).saveThemeMode(mode);
  }
}

/// Провайдер темы оформления; его слушает MarshrutApp (lib/app.dart).
final themeModeProvider = NotifierProvider<ThemeModeController, String>(
  ThemeModeController.new,
);
