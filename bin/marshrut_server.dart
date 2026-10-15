// Программа-сервер API «Маршрута». Её запускают на компьютере (ноутбуке),
// а приложение на телефоне или в Windows подключается к ней по сети.
// Сервер хранит все данные в файле базы SQLite и отвечает на запросы
// приложения (обработчики — lib/server/api_server.dart).
//
// Запуск из папки проекта:
//   dart run bin/marshrut_server.dart [--port 8080] [--db файл] [--catalog папка]
// Готовая программа для Windows (marshrut_server.exe) собирается в
// GitHub Actions; как её запустить — docs/Сервер_API.md.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:marshrut/core/utils/password_hasher.dart';
import 'package:marshrut/data/datasources/catalog_repository_impl.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/server/api_server.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> args) async {
  // Разбираем параметры командной строки вида «--port 8080».
  final options = _parseArgs(args);
  final port = int.tryParse(options['port'] ?? '') ?? 8080;
  final dbPath = options['db'] ?? 'marshrut_server.sqlite';

  // Находим папку с каталогом тем и читаем все направления.
  final catalogDir = _findCatalog(options['catalog']);
  if (catalogDir == null) {
    stderr.writeln('Не найдена папка каталога тем (catalog).');
    exitCode = 1;
    return;
  }
  final catalog = <Object?>[];
  for (final path in CatalogRepositoryImpl.files) {
    // Имя файла берём из пути assets/catalog/<имя>.json.
    final file = File('${catalogDir.path}/${path.split('/').last}');
    catalog.add(jsonDecode(await file.readAsString()));
  }

  // Открываем (или создаём) файл базы данных SQLite. Запросы к базе
  // выполняются в фоновом изоляте, чтобы сервер не замирал.
  final dbFile = File(dbPath).absolute;
  final db = AppDatabase(NativeDatabase.createInBackground(dbFile));

  // Создаём обработчик API; журнал запросов печатается в окно сервера.
  final api = ApiServer(
    db: db,
    catalog: catalog,
    hasher: PasswordHasher(),
    log: stdout.writeln,
  );

  // Запускаем HTTP-сервер на всех сетевых адресах компьютера.
  final HttpServer server;
  try {
    server = await shelf_io.serve(api.handler, InternetAddress.anyIPv4, port);
  } on SocketException catch (e) {
    stderr.writeln('Не удалось занять порт $port: ${e.message}');
    stderr.writeln('Возможно, сервер уже запущен в другом окне.');
    await db.close();
    exitCode = 1;
    return;
  }

  // Печатаем адреса, по которым к серверу можно подключиться.
  stdout.writeln('Сервер «Маршрут» запущен.');
  stdout.writeln('База данных: ${dbFile.path}');
  stdout.writeln('');
  stdout.writeln('Адрес для приложения на этом компьютере:');
  stdout.writeln('  http://localhost:$port');
  final addresses = await _localAddresses();
  if (addresses.isNotEmpty) {
    stdout.writeln('Адрес для телефона в той же сети Wi-Fi:');
    for (final address in addresses) {
      stdout.writeln('  http://$address:$port');
    }
  }
  stdout.writeln('');
  stdout.writeln('Не закрывайте это окно, пока работаете с приложением.');
  stdout.writeln('Журнал запросов:');

  // По Ctrl+C аккуратно останавливаем сервер и закрываем базу.
  late final StreamSubscription<ProcessSignal> stop;
  stop = ProcessSignal.sigint.watch().listen((_) async {
    stdout.writeln('Сервер остановлен.');
    await server.close(force: true);
    await db.close();
    await stop.cancel();
  });
}

/// Разбирает параметры вида `--имя значение` в словарь.
Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i].startsWith('--')) result[args[i].substring(2)] = args[i + 1];
  }
  return result;
}

/// Ищет папку каталога: указанную в `--catalog`, рядом с программой
/// (папка catalog в готовой сборке) или assets/catalog в папке проекта.
Directory? _findCatalog(String? explicit) {
  final exeDir = File(Platform.resolvedExecutable).parent;
  final candidates = [
    ?explicit,
    '${exeDir.path}/catalog',
    '${exeDir.parent.path}/catalog',
    'catalog',
    'assets/catalog',
  ];
  for (final path in candidates) {
    final dir = Directory(path);
    if (File('${dir.path}/flutter.json').existsSync()) return dir;
  }
  return null;
}

/// Адреса IPv4 этого компьютера в локальной сети (например, 192.168.1.5),
/// кроме служебного 127.0.0.1.
Future<List<String>> _localAddresses() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
  );
  return [
    for (final interface in interfaces)
      for (final address in interface.addresses)
        if (!address.isLoopback) address.address,
  ];
}
