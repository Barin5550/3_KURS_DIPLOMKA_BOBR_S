// Пользователи через API: регистрация, вход, профиль, пароль, напоминание
// и удаление аккаунта. Слой: data. Реализует интерфейс AuthRepository из
// domain запросами к серверу (адреса /api/auth/... и /api/me). Пароли
// приложение не хэширует и не хранит: проверяет их сервер.

import '../../domain/entities/user.dart';
import '../../domain/repositories/repositories.dart';
import 'api_client.dart';
import 'api_json.dart';

/// Репозиторий пользователей, работающий через сервер API.
class ApiAuthRepository implements AuthRepository {
  /// [api] — клиент, через который идут запросы.
  ApiAuthRepository(this._api);

  /// Клиент API.
  final ApiClient _api;

  /// POST /api/auth/register — создаёт аккаунт и возвращает пользователя.
  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return userFromJson(data as Json);
  }

  /// POST /api/auth/login — вход. Сервер возвращает токен, клиент API
  /// запоминает его и дальше отправляет с каждым запросом.
  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/api/auth/login', {
      'email': email,
      'password': password,
    }) as Json;
    _api.token = data['token'] as String;
    return userFromJson(data['user'] as Json);
  }

  /// GET /api/me — данные вошедшего пользователя. Через API доступен
  /// только свой аккаунт, поэтому для чужого [id] ответ — `null`.
  @override
  Future<AppUser?> userById(int id) async {
    // Без токена сервер всё равно ответит «нужно войти».
    if (_api.token == null) return null;
    try {
      final user = userFromJson(await _api.get('/api/me') as Json);
      return user.id == id ? user : null;
    } on ApiException catch (e) {
      // 401 — токен устарел или аккаунт удалён: пользователь не вошёл.
      if (e.statusCode == 401) return null;
      rethrow;
    }
  }

  /// PUT /api/me — новое имя, email и цвет аватара.
  @override
  Future<AppUser> updateProfile({
    required int userId,
    required String name,
    required String email,
    required int avatarColor,
  }) async {
    final data = await _api.put('/api/me', {
      'name': name,
      'email': email,
      'avatarColor': avatarColor,
    });
    return userFromJson(data as Json);
  }

  /// PUT /api/me/password — смена пароля (сервер проверит текущий).
  @override
  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) => _api.put('/api/me/password', {
    'oldPassword': oldPassword,
    'newPassword': newPassword,
  });

  /// DELETE /api/me — удаление аккаунта с подтверждением паролем.
  @override
  Future<void> deleteAccount({required int userId, required String password}) =>
      _api.delete('/api/me', {'password': password});

  /// PUT /api/me/reminder — включение и время ежедневного напоминания.
  @override
  Future<AppUser> updateReminder({
    required int userId,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    final data = await _api.put('/api/me/reminder', {
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
    });
    return userFromJson(data as Json);
  }

  /// POST /api/auth/logout — сервер забывает токен. Ошибки (например, нет
  /// связи) не мешают выйти: токен в приложении всё равно стирается.
  Future<void> logout() async {
    try {
      if (_api.token != null) await _api.post('/api/auth/logout');
    } on AppException {
      // Сервер недоступен — просто выходим локально.
    } finally {
      _api.token = null;
    }
  }
}
