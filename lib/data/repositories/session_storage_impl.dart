// Хранилище сессии и настроек на устройстве (слой data).
// Реализует интерфейс SessionStorage из слоя domain: запоминает вошедшего
// пользователя и его токен API («Запомнить меня»), адрес сервера API и
// выбранную тему оформления. Это настройки самого приложения, а не данные
// пользователя: планы, заметки и профиль хранятся на сервере.
// Создаётся в sessionStorageProvider (presentation/providers/providers.dart),
// используется AuthController, ThemeModeController и apiClientProvider.

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/repositories.dart';

/// Сессия пользователя и настройки приложения в shared_preferences.
///
/// shared_preferences — пакет для хранения простых пар «ключ — значение»
/// на устройстве (на Android это SharedPreferences, на iOS — UserDefaults).
class SessionStorageImpl implements SessionStorage {
  /// Получает уже открытое хранилище настроек (создаётся в main()).
  SessionStorageImpl(this._prefs);

  /// Адрес сервера по умолчанию: сервер на этом же компьютере. Для
  /// телефона адрес меняют на экране входа («Сервер API»).
  static const defaultServerUrl = 'http://localhost:8080';

  /// Объект shared_preferences, через который читаются и пишутся значения.
  final SharedPreferences _prefs;

  /// Ключ, под которым хранится id текущего пользователя.
  static const _userKey = 'current_user_id';

  /// Ключ, под которым хранится токен входа в API.
  static const _tokenKey = 'auth_token';

  /// Ключ, под которым хранится адрес сервера API.
  static const _serverKey = 'server_url';

  /// Ключ, под которым хранится тема оформления.
  static const _themeKey = 'theme_mode';

  /// Id пользователя, который вошёл с «Запомнить меня», или `null`.
  @override
  int? get currentUserId => _prefs.getInt(_userKey);

  /// Токен входа запомненного пользователя или `null`.
  @override
  String? get authToken => _prefs.getString(_tokenKey);

  /// Сохраняет id пользователя и токен; если чего-то нет — «никто не вошёл».
  @override
  Future<void> saveSession({int? userId, String? token}) async {
    // При выходе (или без «Запомнить меня») ключи удаляются целиком.
    if (userId == null || token == null) {
      await _prefs.remove(_userKey);
      await _prefs.remove(_tokenKey);
    } else {
      // Иначе запоминаем, чтобы при следующем запуске войти сразу.
      await _prefs.setInt(_userKey, userId);
      await _prefs.setString(_tokenKey, token);
    }
  }

  /// Адрес сервера API; если его ещё не меняли — [defaultServerUrl].
  @override
  String get serverUrl => _prefs.getString(_serverKey) ?? defaultServerUrl;

  /// Запоминает адрес сервера API.
  @override
  Future<void> saveServerUrl(String url) => _prefs.setString(_serverKey, url);

  /// Тема оформления: 'system', 'light' или 'dark'.
  /// Если пользователь ещё ничего не выбирал — 'system' (как в системе).
  @override
  String get themeMode => _prefs.getString(_themeKey) ?? 'system';

  /// Запоминает выбранную тему оформления.
  @override
  Future<void> saveThemeMode(String mode) => _prefs.setString(_themeKey, mode);
}
