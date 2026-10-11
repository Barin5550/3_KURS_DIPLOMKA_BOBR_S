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
@visibleForTesting
String? authRedirect(AuthStatus status, String location) {
  if (status == AuthStatus.unknown) {
    return location == '/splash' ? null : '/splash';
  }
  final loggedIn = status == AuthStatus.authenticated;
  final isPublic = publicRoutes.contains(location);
  if (!loggedIn) return isPublic ? null : '/login';
  if (isPublic || location == '/splash') return '/home';
  return null;
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // Роутер пересчитывает redirect каждый раз, когда меняется состояние входа.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => authRedirect(
      ref.read(authControllerProvider).status,
      state.matchedLocation,
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          initialEmail: state.uri.queryParameters['email'],
          justRegistered: state.uri.queryParameters['registered'] == '1',
        ),
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),

      // Онбординг: создание нового плана.
      GoRoute(
        path: '/onboarding',
        builder: (_, _) => const DirectionScreen(),
        routes: [
          GoRoute(path: 'test', builder: (_, _) => const DiagnosticScreen()),
          GoRoute(path: 'schedule', builder: (_, _) => const ScheduleScreen()),
          GoRoute(path: 'preview', builder: (_, _) => const PreviewScreen()),
        ],
      ),

      // Основные вкладки с нижней навигацией.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/plan', builder: (_, _) => const PlanScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/topics', builder: (_, _) => const TopicsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (_, _) => const StatsScreen()),
            ],
          ),
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
      GoRoute(
        path: '/session/:id',
        builder: (_, state) =>
            SessionScreen(sessionId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/plans', builder: (_, _) => const PlansScreen()),
      GoRoute(
        path: '/plan/settings',
        builder: (_, _) => const PlanSettingsScreen(),
      ),
      GoRoute(
        path: '/pomodoro',
        builder: (_, state) =>
            PomodoroScreen(topicTitle: state.uri.queryParameters['topic']),
      ),
      GoRoute(
        path: '/topic/:id',
        builder: (_, state) =>
            TopicScreen(topicId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/topics/custom/new',
        builder: (_, state) => CustomTopicScreen(
          directionId: state.uri.queryParameters['direction'],
        ),
      ),
      GoRoute(
        path: '/topics/custom/:id',
        builder: (_, state) =>
            CustomTopicScreen(topicId: state.pathParameters['id']),
      ),
      GoRoute(path: '/notes', builder: (_, _) => const NotesScreen()),
      GoRoute(
        path: '/notes/edit',
        builder: (_, state) {
          final q = state.uri.queryParameters;
          return NoteEditScreen(
            // Новый ключ для каждой заметки: иначе при переходе между
            // заметками сохранялось бы состояние предыдущей.
            key: ValueKey(state.uri.toString()),
            noteId: int.tryParse(q['id'] ?? ''),
            topicId: q['topicId'],
            topicTitle: q['topicTitle'],
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
