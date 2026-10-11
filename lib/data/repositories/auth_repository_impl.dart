import 'package:drift/drift.dart';

import '../../core/utils/password_hasher.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/repositories.dart';
import '../db/app_database.dart';

/// Цвета аватаров по умолчанию (выбираются по кругу при регистрации).
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
  AuthRepositoryImpl(this._db, {PasswordHasher? hasher})
    : _hasher = hasher ?? PasswordHasher();

  final AppDatabase _db;
  final PasswordHasher _hasher;

  static const invalidCredentials = 'Неверный email или пароль';

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalized = _normalize(email);
    if (await _findByEmail(normalized) != null) {
      throw const AppException('Пользователь с таким email уже существует');
    }
    final salt = _hasher.generateSalt();
    final count = await _db.users.count().getSingle();
    final id = await _db
        .into(_db.users)
        .insert(
          UsersCompanion.insert(
            name: name.trim(),
            email: normalized,
            passwordHash: await _hasher.hashAsync(password, salt),
            salt: salt,
            avatarColor: avatarPalette[count % avatarPalette.length],
            createdAt: DateTime.now(),
          ),
        );
    return (await userById(id))!;
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
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
    return _toEntity(row);
  }

  @override
  Future<AppUser?> userById(int id) async {
    final row = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  @override
  Future<AppUser> updateProfile({
    required int userId,
    required String name,
    required String email,
    required int avatarColor,
  }) async {
    final normalized = _normalize(email);
    final existing = await _findByEmail(normalized);
    if (existing != null && existing.id != userId) {
      throw const AppException('Этот email уже занят другим пользователем');
    }
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        name: Value(name.trim()),
        email: Value(normalized),
        avatarColor: Value(avatarColor),
      ),
    );
    return (await userById(userId))!;
  }

  @override
  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final row = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(userId))).getSingle();
    if (!await _hasher.verifyAsync(oldPassword, row.salt, row.passwordHash)) {
      throw const AppException('Текущий пароль указан неверно');
    }
    if (oldPassword == newPassword) {
      throw const AppException('Новый пароль должен отличаться от текущего');
    }
    await _savePassword(userId, newPassword);
  }

  @override
  Future<void> deleteAccount({
    required int userId,
    required String password,
  }) async {
    final row = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(userId))).getSingleOrNull();
    if (row == null) throw const AppException('Пользователь не найден');
    if (!await _hasher.verifyAsync(password, row.salt, row.passwordHash)) {
      throw const AppException('Пароль указан неверно');
    }
    // Планы, занятия, заметки, свои темы, избранное и «помидоры» удаляются
    // каскадно (FOREIGN KEY … ON DELETE CASCADE).
    await (_db.delete(_db.users)..where((u) => u.id.equals(userId))).go();
  }

  /// Сохраняет пароль с новой солью в текущем формате хэша.
  Future<void> _savePassword(int userId, String password) async {
    final salt = _hasher.generateSalt();
    final hash = await _hasher.hashAsync(password, salt);
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(salt: Value(salt), passwordHash: Value(hash)),
    );
  }

  @override
  Future<AppUser> updateReminder({
    required int userId,
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await (_db.update(_db.users)..where((u) => u.id.equals(userId))).write(
      UsersCompanion(
        reminderEnabled: Value(enabled),
        reminderHour: Value(hour),
        reminderMinute: Value(minute),
      ),
    );
    return (await userById(userId))!;
  }

  Future<UserRow?> _findByEmail(String email) => (_db.select(
    _db.users,
  )..where((u) => u.email.equals(email))).getSingleOrNull();

  String _normalize(String email) => email.trim().toLowerCase();

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
