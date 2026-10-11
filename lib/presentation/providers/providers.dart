import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// -------------------------------------------------------------------------
// Внешние зависимости. Переопределяются в main() и в тестах через overrides.
// -------------------------------------------------------------------------

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider не переопределён'),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('sharedPreferencesProvider не переопределён'),
);

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => LocalReminderService(),
);

/// Источник текущего времени (в тестах подменяется фиксированной датой).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final todayProvider = Provider<DateTime>(
  (ref) => dateOnly(ref.watch(clockProvider)()),
);

// -------------------------------------------------------------------------
// Репозитории слоя data.
// -------------------------------------------------------------------------

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepositoryImpl(rootBundle.loadString),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.watch(databaseProvider)),
);

final sessionStorageProvider = Provider<SessionStorage>(
  (ref) => SessionStorageImpl(ref.watch(sharedPreferencesProvider)),
);

final planRepositoryProvider = Provider<PlanRepository>(
  (ref) => PlanRepositoryImpl(ref.watch(databaseProvider)),
);

final topicRepositoryProvider = Provider<TopicRepositoryImpl>(
  (ref) => TopicRepositoryImpl(ref.watch(databaseProvider)),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(ref.watch(databaseProvider)),
);

final pomodoroRepositoryProvider = Provider<PomodoroRepository>(
  (ref) => PomodoroRepositoryImpl(ref.watch(databaseProvider)),
);

final planServiceProvider = Provider<PlanService>(
  (ref) => PlanService(
    ref.watch(planRepositoryProvider),
    clock: ref.watch(clockProvider),
  ),
);

// -------------------------------------------------------------------------
// Пользователь.
// -------------------------------------------------------------------------

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.user?.id)),
);

// -------------------------------------------------------------------------
// Каталог.
// -------------------------------------------------------------------------

final directionsProvider = FutureProvider<List<Direction>>(
  (ref) => ref.watch(catalogRepositoryProvider).loadDirections(),
);

final directionProvider = FutureProvider.family<Direction?, String>((
  ref,
  id,
) async {
  final directions = await ref.watch(directionsProvider.future);
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
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref
      .watch(topicRepositoryProvider)
      .watchCustomTopics(userId, directionId: directionId);
});

/// Темы направления: каталог + свои темы пользователя.
final directionTopicsProvider = FutureProvider.family<List<Topic>, String>((
  ref,
  directionId,
) async {
  final direction = await ref.watch(directionProvider(directionId).future);
  final custom = await ref.watch(customTopicsProvider(directionId).future);
  return [...?direction?.topics, ...custom];
});

final favoritesProvider = StreamProvider<Set<String>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const {});
  return ref.watch(topicRepositoryProvider).watchFavorites(userId);
});

// -------------------------------------------------------------------------
// Планы и занятия.
// -------------------------------------------------------------------------

final plansProvider = StreamProvider<List<StudyPlan>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(planRepositoryProvider).watchPlans(userId);
});

final activePlanProvider = StreamProvider<StudyPlan?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  return ref.watch(planRepositoryProvider).watchActivePlan(userId);
});

final planSessionsProvider = StreamProvider.family<List<StudySession>, int>(
  (ref, planId) => ref.watch(planRepositoryProvider).watchSessions(planId),
);

final planProgressProvider = Provider.family<AsyncValue<PlanProgress>, int>(
  (ref, planId) => ref
      .watch(planSessionsProvider(planId))
      .whenData((s) => PlanProgress.fromSessions(s, ref.watch(todayProvider))),
);

final completedSessionsProvider = StreamProvider<List<StudySession>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(planRepositoryProvider).watchCompletedSessions(userId);
});

// -------------------------------------------------------------------------
// Заметки и Pomodoro.
// -------------------------------------------------------------------------

final notesProvider = StreamProvider.family<List<Note>, String?>((
  ref,
  topicId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(noteRepositoryProvider).watchNotes(userId, topicId: topicId);
});

final pomodorosProvider = StreamProvider<List<PomodoroEntry>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(pomodoroRepositoryProvider).watchPomodoros(userId);
});

// -------------------------------------------------------------------------
// Тема оформления.
// -------------------------------------------------------------------------

class ThemeModeController extends Notifier<String> {
  @override
  String build() => ref.watch(sessionStorageProvider).themeMode;

  Future<void> set(String mode) async {
    state = mode;
    await ref.read(sessionStorageProvider).saveThemeMode(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, String>(
  ThemeModeController.new,
);
