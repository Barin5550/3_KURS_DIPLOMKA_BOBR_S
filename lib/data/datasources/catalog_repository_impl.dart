import 'dart:convert';

import '../../domain/entities/direction.dart';
import '../../domain/repositories/repositories.dart';

typedef AssetReader = Future<String> Function(String path);

/// Каталог направлений хранится в JSON-файлах в assets/catalog.
class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(this._readAsset);

  static const files = [
    'assets/catalog/flutter.json',
    'assets/catalog/python.json',
    'assets/catalog/english.json',
    'assets/catalog/algorithms.json',
  ];

  final AssetReader _readAsset;
  List<Direction>? _cache;

  @override
  Future<List<Direction>> loadDirections() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final result = <Direction>[];
      for (final path in files) {
        final json = jsonDecode(await _readAsset(path)) as Map<String, dynamic>;
        result.add(Direction.fromJson(json));
      }
      return _cache = result;
    } on FormatException catch (e) {
      throw AppException('Каталог тем повреждён: ${e.message}');
    }
  }
}
