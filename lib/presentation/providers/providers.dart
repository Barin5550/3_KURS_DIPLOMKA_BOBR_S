// Все провайдеры Riverpod приложения в одном месте (слой presentation).
// Здесь собирается граф зависимостей: клиент API → репозитории слоя data,
// которые обращаются к серверу → сервисы → данные для экранов (планы,
// темы, заметки, тема оформления). Экраны получают данные только через эти
// провайдеры, а main() и тесты подставляют настройки и HTTP-клиент через
// overrides.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/api_auth_repository.dart';
import '../../data/api/api_catalog_repository.dart';
import '../../data/api/api_client.dart';
import '../../data/api/api_note_repository.dart';
import '../../data/api/api_plan_repository.dart';
import '../../data/api/api_topic_repository.dart';
import '../../data/repositories/session_storage_impl.dart';
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

/// Правило повторов для ProviderScope: не повторять автоматически.
///
/// Riverpod сам повторяет упавший провайдер до 10 раз (около 40 секунд), и
/// всё это время экран показывал бы загрузку. Для данных с сервера лучше
/// сразу показать ошибку («Нет связи с сервером …») с кнопкой «Повторить»;
/// потоки ApiClient.watch и так повторяют запрос сами.
Duration? noAutoRetry(int retryCount, Object error) => null;

// -------------------------------------------------------------------------
// Внешние зависимости. Переопределяются в main() и в тестах через overrides.
// -------------------------------------------------------------------------

/// Хранилище простых настроек shared_preferences. Подставляется в main()
/// (его открытие асинхронное, поэтому делается заранее).
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
// Работа с сервером API и репозитории слоя data.
// -------------------------------------------------------------------------

/// Хранилище сессии («Запомнить меня»), адреса сервера и темы оформления.
final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorageImpl(ref.watch(sharedPreferencesProvider)),
);

/// Объект пакета http, который отправляет запросы по сети. В тестах
/// подменяется клиентом, который передаёт запросы серверу прямо в памяти.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  // Когда провайдер больше не нужен, закрываем сетевые соединения.
  ref.onDispose(client.close);
  return client;
});

/// Клиент API: через него идут все запросы к данным. Адрес сервера и
/// сохранённый токен входа берёт из хранилища сессии.
final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(sessionStorageProvider);
  final client = ApiClient(
    baseUrl: storage.serverUrl,
    token: storage.authToken,
    httpClient: ref.watch(httpClientProvider),
  );
  // Сервер ответил 401 («нужно войти»): токен больше не действует,
  // поэтому выходим из аккаунта и показываем экран входа.
  client.onUnauthorized = () =>
      ref.read(authControllerProvider.notifier).onSessionExpired();
  ref.onDispose(client.close);
  return client;
});

/// Каталог направлений и тем: загружается с сервера (GET /api/directions).
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => ApiCatalogRepository(ref.watch(apiClientProvider)),
);

/// Репозиторий пользователей: регистрация, вход, профиль. Тип — сама
/// реализация API: AuthController нужен её метод `logout` (выход на
/// сервере).
final authRepositoryProvider = Provider<ApiAuthRepository>(
  (ref) => ApiAuthRepository(ref.watch(apiClientProvider)),
);

/// Репозиторий планов, тем плана и занятий.
final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => ApiPlanRepository(ref.watch(apiClientProvider)),
);

/// Репозиторий своих тем и избранного.
final topicRepositoryProvider = Provider<TopicRepository>(
  (ref) => ApiTopicRepository(ref.watch(apiClientProvider)),
);

/// Репозиторий заметок.
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => ApiNoteRepository(ref.watch(apiClientProvider)),
);

/// Репозиторий журнала «помидоров» (Pomodoro).
final pomodoroRepositoryProvider = Provider<PomodoroRepository>(
  (ref) => ApiPomodoroRepository(ref.watch(apiClientProvider)),
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
  // Без вошедшего пользователя избранного нет.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const {});
  // Поток id избранных тем из базы.
  return ref.watch(topicRepositoryProvider).watchFavorites(userId);
});

// -------------------------------------------------------------------------
// Планы и занятия.
// -------------------------------------------------------------------------

/// Все планы вошедшего пользователя (обновляются при изменениях в базе).
final plansProvider = StreamProvider<List<StudyPlan>>((ref) {
  // Пока никто не вошёл — пустой список.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  // Поток планов пользователя из репозитория.
  return ref.watch(planRepositoryProvider).watchPlans(userId);
});

/// Активный план пользователя или `null`, если планов нет.
final activePlanProvider = StreamProvider<StudyPlan?>((ref) {
  // Пока никто не вошёл — активного плана нет.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  // Поток активного плана из репозитория.
  return ref.watch(planRepositoryProvider).watchActivePlan(userId);
});

/// Занятия плана с id [planId], по датам.
final planSessionsProvider = StreamProvider.family<List<StudySession>, int>(
  // Просто отдаём поток занятий из репозитория.
  (ref, planId) => ref.watch(planRepositoryProvider).watchSessions(planId),
);

/// Прогресс плана (сколько выполнено), посчитанный по его занятиям.
///
/// AsyncValue — обёртка «загружается / ошибка / готово»; whenData
/// пересчитывает только готовое значение.
final planProgressProvider = Provider.family<AsyncValue<PlanProgress>, int>(
  // Берём занятия плана и, когда они загружены, считаем по ним прогресс
  // относительно сегодняшней даты.
  (ref, planId) => ref
      .watch(planSessionsProvider(planId))
      .whenData((s) => PlanProgress.fromSessions(s, ref.watch(todayProvider))),
);

/// Все выполненные занятия пользователя (для статистики и истории).
final completedSessionsProvider = StreamProvider<List<StudySession>>((ref) {
  // Пока никто не вошёл — пустой список.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  // Поток выполненных занятий по всем планам пользователя.
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
  // Пока никто не вошёл — пустой список.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  // Поток заметок из репозитория (с фильтром по теме, если он задан).
  return ref.watch(noteRepositoryProvider).watchNotes(userId, topicId: topicId);
});

/// Журнал завершённых «помидоров» пользователя.
final pomodorosProvider = StreamProvider<List<PomodoroEntry>>((ref) {
  // Пока никто не вошёл — пустой список.
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  // Поток записей журнала из репозитория.
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
    // Новое состояние — все, кто следит за темой, перерисуются.
    state = mode;
    // Запоминаем выбор, чтобы после перезапуска тема осталась той же.
    await ref.read(sessionStorageProvider).saveThemeMode(mode);
  }
}

/// Провайдер темы оформления; его слушает MarshrutApp (lib/app.dart).
final themeModeProvider = NotifierProvider<ThemeModeController, String>(
  ThemeModeController.new,
);

/// Адрес сервера API, к которому подключено приложение.
class ServerUrlController extends Notifier<String> {
  /// Начальное значение — адрес, сохранённый в прошлый раз.
  @override
  String build() => ref.watch(sessionStorageProvider).serverUrl;

  /// Проверяет, что по адресу [url] отвечает сервер «Маршрута»
  /// (GET /api/health), и только тогда сохраняет адрес. Если сервер не
  /// отвечает, бросает AppException с причиной.
  Future<void> change(String url) async {
    // Приводим адрес к виду http://хост:порт.
    final normalized = ApiClient.normalizeUrl(url);
    // Пробный клиент с новым адресом: проверяем связь до сохранения.
    final probe = ApiClient(
      baseUrl: normalized,
      httpClient: ref.read(httpClientProvider),
    );
    try {
      await probe.checkHealth();
    } finally {
      probe.close();
    }
    // Сервер ответил: запоминаем адрес и переключаем на него клиент API.
    await ref.read(sessionStorageProvider).saveServerUrl(normalized);
    ref.read(apiClientProvider).baseUrl = normalized;
    state = normalized;
  }
}

/// Провайдер адреса сервера; его показывают экраны входа и профиля.
final serverUrlProvider = NotifierProvider<ServerUrlController, String>(
  ServerUrlController.new,
);
