import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/repositories.dart';

/// Сессия пользователя и настройки интерфейса в shared_preferences.
class SessionStorageImpl implements SessionStorage {
  SessionStorageImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _userKey = 'current_user_id';
  static const _themeKey = 'theme_mode';

  @override
  int? get currentUserId => _prefs.getInt(_userKey);

  @override
  Future<void> saveCurrentUserId(int? userId) async {
    if (userId == null) {
      await _prefs.remove(_userKey);
    } else {
      await _prefs.setInt(_userKey, userId);
    }
  }

  @override
  String get themeMode => _prefs.getString(_themeKey) ?? 'system';

  @override
  Future<void> saveThemeMode(String mode) => _prefs.setString(_themeKey, mode);
}
