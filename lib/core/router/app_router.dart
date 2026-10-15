// Файл app_router.dart — навигация приложения (какой экран по какому адресу).
// Слой: core (общая инфраструктура). Использует библиотеку go_router
// (маршрутизация по строковым путям вроде '/home') и провайдер авторизации.
// Роутер берёт MarshrutApp (app.dart) через routerProvider.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_controller.dart';
import '../../presentation/providers/providers.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/notes/note_edit_screen.dart';
import '../../presentation/screens/notes/notes_screen.dart';
import '../../presentation/screens/onboarding/diagnostic_screen.dart';
import '../../presentation/screens/onboarding/direction_screen.dart';
import '../../presentation/screens/onboarding/preview_screen.dart';
import '../../presentation/screens/onboarding/schedule_screen.dart';
import '../../presentation/screens/plan/plan_screen.dart';
import '../../presentation/screens/plan/plan_settings_screen.dart';
import '../../presentation/screens/plan/plans_screen.dart';
import '../../presentation/screens/plan/session_screen.dart';
import '../../presentation/screens/pomodoro/pomodoro_screen.dart';
import '../../presentation/screens/profile/change_password_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/shell/main_shell.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/stats/stats_screen.dart';
import '../../presentation/screens/topics/custom_topic_screen.dart';
import '../../presentation/screens/topics/topic_screen.dart';
import '../../presentation/screens/topics/topics_screen.dart';

/// Маршруты, доступные без входа в систему.
const publicRoutes = {'/login', '/register'};

/// Правило доступа к экранам (вынесено в функцию, чтобы его можно было
/// проверить юнит-тестом без запуска интерфейса).
///
/// * пока сессия не проверена — показываем только Splash;
/// * неавторизованный пользователь видит только вход и регистрацию;
/// * авторизованного пользователя с экранов входа и Splash ведём на главную.
///
/// Возвращает адрес, куда нужно перенаправить, или `null`, если можно
/// остаться на запрошенном экране [location].
@visibleForTesting
String? authRedirect(AuthStatus status, String location) {
  // Статус ещё неизвестен (сессия проверяется): держим пользователя
  // на заставке, любой другой адрес перенаправляем на '/splash'.
  if (status == AuthStatus.unknown) {
    return location == '/splash' ? null : '/splash';
  }
  // Вошёл ли пользователь и открыт ли сейчас публичный экран.
  final loggedIn = status == AuthStatus.authenticated;
  final isPublic = publicRoutes.contains(location);
  // Гостя пускаем только на публичные экраны, остальное — на вход.
  if (!loggedIn) return isPublic ? null : '/login';
  // Вошедшему незачем видеть вход, регистрацию и заставку — ведём на главную.
  if (isPublic || location == '/splash') return '/home';
  // Во всех остальных случаях перенаправление не нужно.
  return null;
}

/// Ключ корневого навигатора: через него роутер управляет стеком экранов.
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Провайдер Riverpod (объект, который создаёт и раздаёт зависимость
/// виджетам), хранящий единственный экземпляр роутера [GoRouter].
///
/// Содержит полную карту экранов приложения и правило доступа
/// [authRedirect].
final routerProvider = Provider<GoRouter>((ref) {
  // Роутер пересчитывает redirect каждый раз, когда меняется состояние входа.
  // ValueNotifier — простой «сигнал»: увеличиваем число, роутер это слышит.
  final refresh = ValueNotifier<int>(0);
  // Подписываемся на контроллер авторизации: любое изменение -> сигнал.
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  // Освобождаем сигнал, когда провайдер уничтожается.
  ref.onDispose(refresh.dispose);

  // Создаём сам роутер с настройками и списком маршрутов.
  final router = GoRouter(
    // Корневой навигатор приложения.
    navigatorKey: _rootKey,
    // При запуске всегда открываем заставку.
    initialLocation: '/splash',
    // Перепроверять redirect при каждом сигнале refresh.
    refreshListenable: refresh,
    // Перед каждым переходом спрашиваем authRedirect, пускать ли на экран.
    redirect: (context, state) => authRedirect(
      ref.read(authControllerProvider).status,
      state.matchedLocation,
    ),
    // Список всех маршрутов (путь -> экран).
    routes: [
      // Заставка при запуске.
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      // Экран входа. Параметры адреса: email — подставить в поле,
      // registered=1 — показать сообщение об успешной регистрации.
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          initialEmail: state.uri.queryParameters['email'],
          justRegistered: state.uri.queryParameters['registered'] == '1',
        ),
      ),
      // Экран регистрации.
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // Онбординг: создание нового плана.
      // Шаги: выбор направления -> тест -> расписание -> предпросмотр.
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const DirectionScreen(),
        // Вложенные пути: /onboarding/test, /onboarding/schedule и т. д.
        routes: [
          GoRoute(path: 'test', builder: (_, _) => const DiagnosticScreen()),
          GoRoute(path: 'schedule', builder: (_, _) => const ScheduleScreen()),
          GoRoute(path: 'preview', builder: (_, _) => const PreviewScreen()),
        ],
      ),

      // Основные вкладки с нижней навигацией.
      // indexedStack хранит все вкладки в памяти, поэтому при переключении
      // каждая сохраняет своё состояние (прокрутку, введённые данные).
      StatefulShellRoute.indexedStack(
        // MainShell — оболочка с панелью навигации вокруг текущей вкладки.
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        // Каждая ветка — отдельная вкладка со своей историей переходов.
        branches: [
          // Вкладка «Главная».
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          // Вкладка «План».
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
            ],
          ),
          // Вкладка «Темы».
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/topics', builder: (_, _) => const TopicsScreen()),
            ],
          ),
          // Вкладка «Статистика».
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (_, _) => const StatsScreen()),
            ],
          ),
          // Вкладка «Профиль».
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Экраны поверх вкладок.
      // Занятие по его номеру id из адреса (например, /session/5).
      GoRoute(
        path: '/session/:id',
        builder: (_, state) =>
            SessionScreen(sessionId: int.parse(state.pathParameters['id']!)),
      ),
      // Список всех планов пользователя.
      GoRoute(path: '/plans', builder: (_, _) => const PlansScreen()),
      // Настройки текущего плана.
      GoRoute(
        path: '/plan/settings',
        builder: (_, _) => const PlanSettingsScreen(),
      ),
      // Таймер Помодоро; параметр topic — название темы для подписи на экране.
      GoRoute(
        path: '/pomodoro',
        builder: (_, state) =>
            PomodoroScreen(topicTitle: state.uri.queryParameters['topic']),
      ),
      // Карточка одной темы по её строковому id.
      GoRoute(
        path: '/topic/:id',
        builder: (_, state) =>
            TopicScreen(topicId: state.pathParameters['id']!),
      ),
      // Создание своей темы; direction — направление, куда её добавить.
      // Этот маршрут стоит выше '/topics/custom/:id', чтобы слово 'new'
      // не приняли за id.
      GoRoute(
        path: '/topics/custom/new',
        builder: (_, state) => CustomTopicScreen(
          directionId: state.uri.queryParameters['direction'],
        ),
      ),
      // Редактирование своей темы по её id.
      GoRoute(
        path: '/topics/custom/:id',
        builder: (_, state) =>
            CustomTopicScreen(topicId: state.pathParameters['id']),
      ),
      // Список заметок.
      GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
      // Создание или редактирование заметки.
      GoRoute(
        path: '/notes/edit',
        builder: (_, state) {
          // Параметры адреса: id заметки (если редактируем) и тема,
          // к которой заметка привязана.
          final q = state.uri.queryParameters;
          return NoteEditScreen(
            // Новый ключ для каждой заметки: иначе при переходе между
            // заметками сохранялось бы состояние предыдущей.
            key: ValueKey(state.uri.toString()),
            // Нет id или он не число — значит, создаётся новая заметка.
            noteId: int.tryParse(q['id'] ?? ''),
            topicId: q['topicId'],
            topicTitle: q['topicTitle'],
          );
        },
      ),
      // Редактирование профиля (имя, email).
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      // Смена пароля.
      GoRoute(
        path: '/profile/password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
    ],
  );
  // Освобождаем ресурсы роутера, когда провайдер уничтожается.
  ref.onDispose(router.dispose);
  // Отдаём готовый роутер всем, кто его читает.
  return router;
});
