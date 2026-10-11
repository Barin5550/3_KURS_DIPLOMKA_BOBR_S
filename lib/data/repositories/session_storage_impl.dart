// Хранилище сессии и настроек интерфейса (слой data).
// Реализует интерфейс SessionStorage из слоя domain: запоминает id вошедшего
// пользователя («Запомнить меня») и выбранную тему оформления.
// Создаётся в sessionStorageProvider (presentation/providers/providers.dart),
// используется AuthController и ThemeModeController.

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/repositories.dart';

/// Сессия пользователя и настройки интерфейса в shared_preferences.
///
/// shared_preferences — пакет для хранения простых пар «ключ — значение»
/// на устройстве (на Android это SharedPreferences, на iOS — UserDefaults).
class SessionStorageImpl implements SessionStorage {
  /// Получает уже открытое хранилище настроек (создаётся в main()).
  SessionStorageImpl(this._prefs);

  /// Объект shared_preferences, через который читаются и пишутся значения.
  final SharedPreferences _prefs;

  /// Ключ, под которым хранится id текущего пользователя.
  static const _userKey = 'current_user_id';

  /// Ключ, под которым хранится тема оформления.
  static const _themeKey = 'theme_mode';

  /// Id пользователя, который вошёл с «Запомнить меня», или `null`.
  @override
  int? get currentUserId => _prefs.getInt(_userKey);

  /// Сохраняет id пользователя; `null` означает «никто не вошёл».
  @override
  Future<void> saveCurrentUserId(int? userId) async {
    // При выходе (или без «Запомнить меня») ключ удаляется целиком.
    if (userId == null) {
      await _prefs.remove(_userKey);
    } else {
      // Иначе id записывается, чтобы при следующем запуске войти сразу.
      await _prefs.setInt(_userKey, userId);
    }
  }

  /// Тема оформления: 'system', 'light' или 'dark'.
  /// Если пользователь ещё ничего не выбирал — 'system' (как в системе).
  @override
  String get themeMode => _prefs.getString(_themeKey) ?? 'system';

  /// Запоминает выбранную тему оформления.
  @override
  Future<void> saveThemeMode(String mode) => _prefs.setString(_themeKey, mode);
}
