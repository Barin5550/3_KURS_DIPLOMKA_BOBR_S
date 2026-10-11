import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'presentation/providers/providers.dart';

/// Точка входа. Создаёт базу данных и настройки, затем запускает приложение.
///
/// Облачные сервисы и ключи не нужны: все данные хранятся на устройстве.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');

  final prefs = await SharedPreferences.getInstance();
  final database = AppDatabase(
    driftDatabase(
      name: 'marshrut',
      // Служебная папка приложения (в Windows — %APPDATA%), а не «Документы».
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MarshrutApp(),
    ),
  );
}
