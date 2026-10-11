import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import 'providers.dart';

enum AuthStatus {
  /// Сессия ещё не проверена (показывается Splash).
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState._(this.status, this.user);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);
  const AuthState.authenticated(AppUser user)
    : this._(AuthStatus.authenticated, user);

  final AuthStatus status;
  final AppUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Состояние входа пользователя в систему.
///
/// Роутер слушает этот контроллер: при смене состояния срабатывает
/// redirect, и закрытые экраны становятся доступны или недоступны.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  /// Автовход: если в прошлый раз пользователь отметил «Запомнить меня»,
  /// его id сохранён в shared_preferences.
  Future<void> restoreSession() async {
    final storage = ref.read(sessionStorageProvider);
    final id = storage.currentUserId;
    final user = id == null
        ? null
        : await ref.read(authRepositoryProvider).userById(id);
    if (user == null) {
      await storage.saveCurrentUserId(null);
      state = const AuthState.unauthenticated();
    } else {
      state = AuthState.authenticated(user);
      await _syncReminder(user);
    }
  }

  /// Бросает AppException с текстом ошибки при неверных данных.
  Future<void> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    final user = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    await ref
        .read(sessionStorageProvider)
        .saveCurrentUserId(remember ? user.id : null);
    state = AuthState.authenticated(user);
    await _syncReminder(user);
  }

  /// Регистрирует пользователя. Вход выполняется отдельно на экране входа.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) => ref
      .read(authRepositoryProvider)
      .register(name: name, email: email, password: password);

  Future<void> logout() async {
    await ref.read(sessionStorageProvider).saveCurrentUserId(null);
    try {
      await ref.read(reminderServiceProvider).cancelDailyReminder();
    } on Exception {
      // Выход не должен зависеть от работы уведомлений.
    }
    state = const AuthState.unauthenticated();
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required int avatarColor,
  }) async {
    final user = state.user;
    if (user == null) return;
    state = AuthState.authenticated(
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            userId: user.id,
            name: name,
            email: email,
            avatarColor: avatarColor,
          ),
    );
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = state.user;
    if (user == null) return;
    await ref
        .read(authRepositoryProvider)
        .changePassword(
          userId: user.id,
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
  }

  /// Включает или выключает ежедневное напоминание.
  /// Возвращает `false`, если пользователь не дал разрешение на уведомления.
  Future<bool> setReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final user = state.user;
    if (user == null) return false;
    final reminders = ref.read(reminderServiceProvider);
    if (enabled && !await reminders.requestPermission()) return false;
    final updated = await ref
        .read(authRepositoryProvider)
        .updateReminder(
          userId: user.id,
          enabled: enabled,
          hour: hour,
          minute: minute,
        );
    state = AuthState.authenticated(updated);
    await _syncReminder(updated);
    return true;
  }

  Future<void> _syncReminder(AppUser user) async {
    final reminders = ref.read(reminderServiceProvider);
    try {
      if (user.reminderEnabled) {
        await reminders.scheduleDailyReminder(
          hour: user.reminderHour,
          minute: user.reminderMinute,
        );
      } else {
        await reminders.cancelDailyReminder();
      }
    } on Exception {
      // Уведомления не критичны: ошибка платформы не должна мешать входу.
    }
  }
}
