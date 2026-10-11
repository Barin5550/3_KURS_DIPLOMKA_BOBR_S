// Контроллер входа в систему (слой presentation).
// Хранит, вошёл ли пользователь и кто он, и выполняет вход, регистрацию,
// выход, изменение профиля и настройку напоминаний через репозиторий
// AuthRepository и сервис уведомлений. Его слушают роутер
// (core/router) и экраны входа, регистрации, профиля и заставки (Splash).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import 'providers.dart';

/// Этапы проверки входа.
enum AuthStatus {
  /// Сессия ещё не проверена (показывается Splash).
  unknown,

  /// Пользователь вошёл в систему.
  authenticated,

  /// Пользователь не вошёл (показываются экраны входа и регистрации).
  unauthenticated,
}

/// Состояние входа: этап [status] и, если пользователь вошёл, [user].
///
/// Создаётся только через именованные конструкторы, поэтому нельзя
/// получить «вошёл, но без пользователя».
class AuthState {
  /// Закрытый общий конструктор, им пользуются три варианта ниже.
  const AuthState._(this.status, this.user);

  /// Начальное состояние: сессия ещё не проверена.
  const AuthState.unknown() : this._(AuthStatus.unknown, null);

  /// Пользователь не вошёл.
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);

  /// Пользователь [user] вошёл в систему.
  const AuthState.authenticated(AppUser user)
    : this._(AuthStatus.authenticated, user);

  /// Текущий этап проверки входа.
  final AuthStatus status;

  /// Вошедший пользователь или `null`.
  final AppUser? user;

  /// Короткая проверка «пользователь вошёл».
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Состояние входа пользователя в систему.
///
/// Роутер слушает этот контроллер: при смене состояния срабатывает
/// redirect, и закрытые экраны становятся доступны или недоступны.
///
/// Notifier (из библиотеки Riverpod) хранит значение `state`; каждое
/// присваивание `state = ...` сообщает об изменении всем, кто его слушает.
/// `ref.read(...)` — получить другой провайдер (репозиторий, сервис).
class AuthController extends Notifier<AuthState> {
  /// При запуске приложения состояние неизвестно, пока Splash не вызовет
  /// [restoreSession].
  @override
  AuthState build() => const AuthState.unknown();

  /// Автовход: если в прошлый раз пользователь отметил «Запомнить меня»,
  /// его id сохранён в shared_preferences.
  Future<void> restoreSession() async {
    // Хранилище сессии и сохранённый в нём id пользователя.
    final storage = ref.read(sessionStorageProvider);
    final id = storage.currentUserId;
    // Если id есть — загружаем пользователя из базы; его могли удалить.
    final user = id == null
        ? null
        : await ref.read(authRepositoryProvider).userById(id);
    if (user == null) {
      // Никого не помним (или пользователь удалён): стираем id и
      // показываем экран входа.
      await storage.saveCurrentUserId(null);
      state = const AuthState.unauthenticated();
    } else {
      // Пользователь найден — входим без ввода пароля.
      state = AuthState.authenticated(user);
      // Восстанавливаем его ежедневное напоминание на этом устройстве.
      await _syncReminder(user);
    }
  }

  /// Вход по email и паролю. При [remember] = `true` пользователь будет
  /// входить автоматически при следующих запусках.
  ///
  /// Бросает AppException с текстом ошибки при неверных данных.
  Future<void> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    // Проверка email и пароля в репозитории; при ошибке будет исключение.
    final user = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    // «Запомнить меня»: сохраняем id; иначе стираем сохранённый.
    await ref
        .read(sessionStorageProvider)
        .saveCurrentUserId(remember ? user.id : null);
    // Меняем состояние — роутер сам переведёт на главный экран.
    state = AuthState.authenticated(user);
    // Ставим или снимаем напоминание по настройкам пользователя.
    await _syncReminder(user);
  }

  /// Регистрирует пользователя. Вход выполняется отдельно на экране входа.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) => ref
      // Просто передаём данные в репозиторий; состояние не меняется.
      .read(authRepositoryProvider)
      .register(name: name, email: email, password: password);

  /// Выход из системы: забываем пользователя и отменяем напоминание.
  Future<void> logout() async {
    // Стираем сохранённый id, чтобы не было автовхода.
    await ref.read(sessionStorageProvider).saveCurrentUserId(null);
    try {
      // Напоминание больше не нужно — пользователь вышел.
      await ref.read(reminderServiceProvider).cancelDailyReminder();
    } on Exception {
      // Выход не должен зависеть от работы уведомлений.
    }
    // Роутер увидит новое состояние и откроет экран входа.
    state = const AuthState.unauthenticated();
  }

  /// Удаляет аккаунт со всеми данными и выходит из системы.
  Future<void> deleteAccount(String password) async {
    // Без вошедшего пользователя удалять нечего.
    final user = state.user;
    if (user == null) return;
    // Репозиторий проверит пароль и удалит пользователя из базы.
    await ref
        .read(authRepositoryProvider)
        .deleteAccount(userId: user.id, password: password);
    // После удаления выходим так же, как по кнопке «Выйти».
    await logout();
  }

  /// Сохраняет новое имя, email и цвет аватара текущего пользователя.
  Future<void> updateProfile({
    required String name,
    required String email,
    required int avatarColor,
  }) async {
    final user = state.user;
    if (user == null) return;
    // Репозиторий возвращает обновлённого пользователя — кладём его в
    // состояние, чтобы экраны сразу показали новые данные.
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

  /// Смена пароля текущего пользователя. Если старый пароль неверен,
  /// репозиторий бросит AppException.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = state.user;
    if (user == null) return;
    // Всю проверку и сохранение выполняет репозиторий.
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
    // При включении сначала спрашиваем разрешение; отказ — выходим.
    if (enabled && !await reminders.requestPermission()) return false;
    // Сохраняем настройку напоминания в профиле пользователя (в базе).
    final updated = await ref
        .read(authRepositoryProvider)
        .updateReminder(
          userId: user.id,
          enabled: enabled,
          hour: hour,
          minute: minute,
        );
    // Обновляем состояние и ставим (или снимаем) само уведомление.
    state = AuthState.authenticated(updated);
    await _syncReminder(updated);
    return true;
  }

  /// Приводит уведомление на устройстве в соответствие с настройками
  /// пользователя: включено — ставим на его время, выключено — отменяем.
  Future<void> _syncReminder(AppUser user) async {
    final reminders = ref.read(reminderServiceProvider);
    try {
      if (user.reminderEnabled) {
        // Ежедневное напоминание на сохранённые час и минуту.
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
