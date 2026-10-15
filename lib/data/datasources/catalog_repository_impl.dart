// Реализация CatalogRepository (слой data, папка datasources).
// Читает каталог направлений (Flutter, Python, английский, алгоритмы) из
// JSON-файлов в assets/catalog и превращает их в объекты Direction.
// Список файлов (files) использует сервер API (bin/marshrut_server.dart),
// а сам класс — тесты каталога. Приложение получает каталог с сервера
// (lib/data/api/api_catalog_repository.dart).

import 'dart:convert';

import '../../domain/entities/direction.dart';
import '../../domain/repositories/repositories.dart';

/// Тип функции, которая читает текстовый файл по пути [path]. В приложении
/// передаётся `rootBundle.loadString`, в тестах — своя функция.
typedef AssetReader = Future<String> Function(String path);

/// Каталог направлений хранится в JSON-файлах в assets/catalog.
///
/// После первой загрузки результат запоминается (кешируется), и файлы
/// больше не читаются.
class CatalogRepositoryImpl implements CatalogRepository {
  /// Принимает функцию чтения файлов (см. [AssetReader]).
  CatalogRepositoryImpl(this._readAsset);

  /// Пути к JSON-файлам направлений: один файл — одно направление.
  static const files = [
    'assets/catalog/flutter.json',
    'assets/catalog/python.json',
    'assets/catalog/english.json',
    'assets/catalog/algorithms.json',
  ];

  /// Функция чтения файла, переданная в конструктор.
  final AssetReader _readAsset;

  /// Кеш: уже загруженные направления (`null`, пока ничего не загружено).
  List<Direction>? _cache;

  /// Загружает направления из всех файлов [files]. При повторном вызове
  /// возвращает кеш. Если JSON повреждён — бросает [AppException].
  @override
  Future<List<Direction>> loadDirections() async {
    // Каталог уже загружен — сразу отдаём сохранённый результат.
    final cached = _cache;
    if (cached != null) return cached;
    try {
      // Список направлений, который соберём из файлов.
      final result = <Direction>[];
      // Читаем файлы по очереди.
      for (final path in files) {
        // Читаем текст файла и разбираем JSON в словарь «ключ — значение».
        final json = jsonDecode(await _readAsset(path)) as Map<String, dynamic>;
        // Превращаем словарь в объект Direction (направление с темами).
        result.add(Direction.fromJson(json));
      }
      // Запоминаем результат в кеше и возвращаем его.
      return _cache = result;
    } on FormatException catch (e) {
      // Файл оказался некорректным JSON — бросаем понятную пользователю
      // ошибку.
      throw AppException('Каталог тем повреждён: ${e.message}');
    }
  }
}
