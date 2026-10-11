// Репозиторий пользователей: регистрация, вход, профиль (слой data).
// Реализует интерфейс AuthRepository из слоя domain. Пользователи хранятся
// в таблице users локальной базы SQLite (через drift), пароли — только
// в виде хэша с солью (core/utils/password_hasher.dart).
// Создаётся в authRepositoryProvider, вызывается из AuthController.

import 'package:drift/drift.dart';

import '../../core/utils/password_hasher.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/repositories.dart';
import '../db/app_database.dart';

/// Цвета аватаров по умолчанию (выбираются по кругу при регистрации).
///
/// Значения в формате 0xAARRGGBB: синий, зелёный, красный, фиолетовый,
/// оранжевый, бирюзовый. Тот же список показывает экран редактирования
/// профиля для выбора цвета.
const avatarPalette = [
  0xFF3D5AFE,
  0xFF2E7D32,
  0xFFC62828,
  0xFF6A1B9A,
  0xFFEF6C00,
  0xFF00838F,
];

/// Локальная авторизация: пользователи хранятся в SQLite.
class AuthRepositoryImpl implements AuthRepository {
  /// Принимает базу данных и, при желании, свой [PasswordHasher]
  /// (в тестах передают вариант с малым числом итераций, чтобы шло быстрее).
  /// Если [hasher] не передан, создаётся обычный.
  AuthRepositoryImpl(this._db, {PasswordHasher? hasher})
    : _hasher = hasher ?? PasswordHasher();

  /// База данных приложения (таблицы описаны в data/db/app_database.dart).
  final AppDatabase _db;

  /// Объект, который считает и проверяет хэши паролей.
  ///
  /// Хэш — результат необратимого преобразования пароля: по нему нельзя
  /// узнать пароль, но можно проверить, что введён тот же пароль.
  final PasswordHasher _hasher;

  /// Текст ошибки при неверном email или пароле (проверяется в тестах).
  static const invalidCredentials = 'Неверный email или пароль';

  /// Регистрирует нового пользователя и возвращает его.
  ///
  /// Бросает [AppException], если email уже занят.
  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // Приводим email к единому виду: без пробелов и в нижнем регистре.
    final normalized = _normalize(email);
    // Если пользователь с таким email уже есть — регистрация запрещена.
    if (await _findByEmail(normalized) != null) {
      throw const AppException('Пользователь с таким email уже существует');
    }
    // Соль — случайная строка, которая добавляется к паролю перед хэшем.
    final salt = _hasher.generateSalt();
    // Сколько пользователей уже есть — от этого зависит цвет аватара.
    final count = await _db.users.count().getSingle();
    // INSERT в таблицу users; drift возвращает id новой строки.
    final id = await _db
        .into(_db.users)
        .insert(
          UsersCompanion.insert(
            name: name.trim(),
            email: normalized,
            // В базу попадает только хэш пароля, сам пароль не хранится.
            // hashAsync считает хэш в фоне, чтобы интерфейс не зависал.
            passwordHash: await _hasher.hashAsync(password, salt),
            salt: salt,
            // Цвет берётся из палитры по кругу: 0, 1, …, 5, снова 0.
            avatarColor: avatarPalette[count % avatarPalette.length],
            createdAt: DateTime.now(),
          ),
        );
    // Читаем только что созданного пользователя; он точно есть, поэтому «!».
    return (await userById(id))!;
  }

  /// Проверяет email и пароль и возвращает пользователя.
  ///
  /// Бросает [AppException] с текстом [invalidCredentials] при ошибке.
  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    // Ищем пользователя по email (в том же виде, что и при регистрации).
    final row = await _findByEmail(_normalize(email));
    // Одинаковое сообщение для неизвестного email и неверного пароля, чтобы
    // нельзя было подобрать существующие адреса.
    if (row == null ||
        !await _hasher.verifyAsync(password, row.salt, row.passwordHash)) {
      throw const AppException(invalidCredentials);
    }
    // Хэш старого формата (SHA-256 версии 1 семестра) или с меньшим числом
    // итераций пересчитывается: пароль известен только в момент входа.
    if (_hasher.needsRehash(row.passwordHash)) {
      await _savePassword(row.id, password);
    }
    // Переводим строку базы в сущность AppUser.
    return _toEntity(row);
  }

  /// Пользователь по id или `null`, если его нет (например, удалён).
  @override
  Future<AppUser?> userById(int id) async {
    // SELECT * FROM users WHERE id = ? (не больше одной строки).
    final row = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  /// Меняет имя, email и цвет аватара; возвращает обновлённого пользователя.
  ///
  /// Бросает [AppException], если новый email занят другим человеком.
  @override
  Future<AppUser> updateProfile({
    required int userId,
    required String name,
    required String email,
    required int avatarColor,
  }) async {
    // Проверяем, не принадлежит ли email кому-то другому.
    final normalized = _normalize(email);
    final existing = await _findByEmail(normalized);
    // Свой же email оставить можно, чужой — нельзя.
    if (existing != null && existing.id != userId) {
      throw const AppException('Этот email уже занят другим пользователем');
    }
    // UPDATE users ... WHERE id = ? — меняем только три поля.
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        name: Value(name.trim()),
        email: Value(normalized),
        avatarColor: Value(avatarColor),
      ),
    );
    // Возвращаем свежие данные из базы.
    return (await userById(userId))!;
  }

  /// Меняет пароль после проверки текущего.
  ///
  /// Бросает [AppException], если текущий пароль неверен или новый
  /// совпадает со старым.
  @override
  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    // Читаем пользователя (он должен существовать, поэтому getSingle).
    final row = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(userId))).getSingle();
    // Сначала проверяем, что человек знает текущий пароль.
    if (!await _hasher.verifyAsync(oldPassword, row.salt, row.passwordHash)) {
      throw const AppException('Текущий пароль указан неверно');
    }
    // Новый пароль не должен повторять старый.
    if (oldPassword == newPassword) {
      throw const AppException('Новый пароль должен отличаться от текущего');
    }
    // Сохраняем новый пароль с новой солью.
    await _savePassword(userId, newPassword);
  }

  /// Удаляет аккаунт вместе со всеми данными после проверки пароля.
  @override
  Future<void> deleteAccount({
    required int userId,
    required String password,
  }) async {
    // Находим пользователя; если его уже нет — сообщаем об ошибке.
    final row = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(userId))).getSingleOrNull();
    if (row == null) throw const AppException('Пользователь не найден');
    // Удаление возможно только при верном пароле.
    if (!await _hasher.verifyAsync(password, row.salt, row.passwordHash)) {
      throw const AppException('Пароль указан неверно');
    }
    // Планы, занятия, заметки, свои темы, избранное и «помидоры» удаляются
    // каскадно (FOREIGN KEY … ON DELETE CASCADE).
    await (_db.delete(_db.users)..where((u) => u.id.equals(userId))).go();
  }

  /// Сохраняет пароль с новой солью в текущем формате хэша.
  Future<void> _savePassword(int userId, String password) async {
    // Новая случайная соль и хэш пароля с ней.
    final salt = _hasher.generateSalt();
    final hash = await _hasher.hashAsync(password, salt);
    // Записываем соль и хэш в строку пользователя.
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(salt: Value(salt), passwordHash: Value(hash)),
    );
  }

  /// Сохраняет настройки ежедневного напоминания: включено ли оно и время.
  /// Возвращает обновлённого пользователя.
  @override
  Future<AppUser> updateReminder({
    required int userId,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    // UPDATE users: флаг напоминания, час и минута.
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        reminderEnabled: Value(enabled),
        reminderHour: Value(hour),
        reminderMinute: Value(minute),
      ),
    );
    // Возвращаем свежие данные из базы.
    return (await userById(userId))!;
  }

  /// Ищет строку пользователя по уже приведённому к единому виду email.
  Future<UserRow?> _findByEmail(String email) => (_db.select(
    _db.users,
  )..where((u) => u.email.equals(email))).getSingleOrNull();

  /// Приводит email к единому виду: `" Ivan@Mail.ru "` → `"ivan@mail.ru"`.
  /// Так один и тот же адрес не зарегистрируют дважды в разном регистре.
  String _normalize(String email) => email.trim().toLowerCase();

  /// Переводит строку таблицы [UserRow] в сущность [AppUser] слоя domain.
  /// Хэш и соль пароля в сущность не попадают — они нужны только здесь.
  AppUser _toEntity(UserRow row) => AppUser(
    id: row.id,
    name: row.name,
    email: row.email,
    avatarColor: row.avatarColor,
    createdAt: row.createdAt,
    reminderEnabled: row.reminderEnabled,
    reminderHour: row.reminderHour,
    reminderMinute: row.reminderMinute,
  );
}
