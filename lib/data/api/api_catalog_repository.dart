// Каталог направлений и тем через API.
// Слой: data. Реализует интерфейс CatalogRepository: загружает каталог с
// сервера (GET /api/directions) один раз и дальше берёт его из памяти.
// Формат направлений тот же, что в файлах assets/catalog, поэтому
// разбирает их тот же код Direction.fromJson.

import '../../domain/entities/direction.dart';
import '../../domain/repositories/repositories.dart';
import 'api_client.dart';
import 'api_json.dart';

/// Каталог направлений, загруженный с сервера API.
class ApiCatalogRepository implements CatalogRepository {
  /// [api] — клиент, через который идут запросы.
  ApiCatalogRepository(this._api);

  /// Клиент API.
  final ApiClient _api;

  /// Загруженный каталог: каталог меняется только с новой версией
  /// сервера, поэтому его достаточно получить один раз.
  List<Direction>? _cache;

  /// GET /api/directions — все направления с темами и вопросами теста.
  @override
  Future<List<Direction>> loadDirections() async {
    final cached = _cache;
    if (cached != null) return cached;
    final data = await _api.get('/api/directions') as List<dynamic>;
    try {
      return _cache = data.cast<Json>().map(Direction.fromJson).toList();
    } on TypeError {
      throw const AppException('Каталог тем на сервере повреждён');
    }
  }
}
