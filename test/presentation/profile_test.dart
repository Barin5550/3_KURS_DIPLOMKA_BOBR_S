import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marshrut/data/db/app_database.dart';
import 'package:marshrut/data/repositories/auth_repository_impl.dart';
import 'package:marshrut/data/services/reminder_service_impl.dart';

import '../helpers/test_app.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = memoryDatabase());

  Future<void> openProfile(
    WidgetTester tester,
    NoopReminderService reminders,
  ) async {
    final id = await tester.runAsync(
      () async => (await AuthRepositoryImpl(
        db,
      ).register(name: 'Ира', email: 'ira@mail.ru', password: 'secret123')).id,
    );
    await pumpTestApp(
      tester,
      db: db,
      prefs: {'current_user_id': id!},
      reminders: reminders,
    );
    await tester.pump(const Duration(milliseconds: 1600));
    await settle(tester);
    await tester.tap(find.text('Профиль').last);
    await settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('reminder_switch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.runAsync(db.close);
  }

  testWidgets('напоминание включается и планируется', (tester) async {
    final reminders = NoopReminderService();
    await openProfile(tester, reminders);
    await tester.tap(find.byKey(const Key('reminder_switch')));
    await settle(tester);
    expect(find.textContaining('Каждый день в'), findsOneWidget);
    expect(reminders.log.last, startsWith('schedule'));
    await finish(tester);
  });

  testWidgets('на настольной платформе переключатель недоступен', (
    tester,
  ) async {
    final reminders = NoopReminderService(supportsDailyReminders: false);
    await openProfile(tester, reminders);
    expect(find.text('Доступно в версии для Android и iOS'), findsOneWidget);
    final tile = tester.widget<SwitchListTile>(
      find.byKey(const Key('reminder_switch')),
    );
    expect(tile.onChanged, isNull);
    await finish(tester);
  });
}
