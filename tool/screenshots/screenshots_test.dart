// Генератор скриншотов экранов для отчёта по курсовой работе.
//
// Запуск:  flutter test tool/screenshots/screenshots_test.dart
// Результат: docs/coursework/screenshots/*.png
//
// Приложение запускается с тестовыми данными (база в памяти, фиксированная
// дата 12.10.2026) и настоящими шрифтами Roboto и Material Icons из Flutter SDK.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marshrut/app.dart';
import 'package:marshrut/presentation/providers/providers.dart';

import '../../test/helpers/test_app.dart';
import 'screenshot_support.dart';

const _outDir = 'docs/coursework/screenshots';
const _ratio = 2.75;
final _boundary = GlobalKey();

void main() {
  testWidgets('скриншоты экранов', (tester) async {
    // В тестах тени по умолчанию рисуются чёрной рамкой; для скриншотов
    // включаем настоящие тени.
    debugDisableShadows = false;
    await tester.runAsync(loadScreenshotFonts);
    Directory(_outDir).createSync(recursive: true);

    final db = memoryDatabase();
    await tester.runAsync(() => seedDemoUser(db));
    final overrides = await tester.runAsync(() => testOverrides(db: db));

    Future<void> setSize(Size size) async {
      tester.view.devicePixelRatio = _ratio;
      tester.view.physicalSize = size * _ratio;
      await tester.pump();
    }

    await setSize(phoneSize);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _boundary,
        child: ProviderScope(
          overrides: overrides!,
          retry: noAutoRetry,
          child: const MarshrutApp(),
        ),
      ),
    );

    Future<void> shot(String name) async {
      await settle(tester, rounds: 6);
      final boundary =
          _boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: _ratio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        return data!.buffer.asUint8List();
      });
      File('$_outDir/$name.png').writeAsBytesSync(bytes!);
    }

    Future<void> tap(Finder finder) async {
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          300,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.ensureVisible(finder);
      // Без кадра после прокрутки tap() берёт старые координаты.
      await tester.pump();
      await tester.tap(finder);
      await settle(tester);
    }

    GoRouter router() =>
        GoRouter.of(tester.element(find.byType(Scaffold).first));

    Future<void> go(String location) async {
      router().go(location);
      await settle(tester);
    }

    // Splash: снимок до автоматического перехода.
    await tester.pump(const Duration(milliseconds: 300));
    await shot('01_splash');
    await tester.pump(const Duration(milliseconds: 1500));
    await settle(tester);

    await shot('02_login');
    // Окно адреса сервера API (кнопка «Сервер: …» под формой входа).
    await tap(find.byKey(const Key('server_settings')));
    await tester.enterText(
      find.byKey(const Key('server_url_field')),
      'http://192.168.1.5:8080',
    );
    await shot('26_server_address');
    await tap(find.text('Отмена'));
    await tap(find.byKey(const Key('go_register')));
    await tap(find.byKey(const Key('reg_submit')));
    await shot('03_register_validation');
    await go('/login');
    await tester.enterText(
      find.byKey(const Key('login_email')),
      'aliya@mail.ru',
    );
    await tester.enterText(find.byKey(const Key('login_password')), 'wrong123');
    await tap(find.byKey(const Key('login_submit')));
    await shot('04_login_error');
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'flutter2026',
    );
    await tap(find.byKey(const Key('login_submit')));

    await shot('05_home');
    await go('/plan');
    await shot('06_plan');
    final sessionTile = find.byKey(const Key('session_tile_first'));
    if (sessionTile.evaluate().isNotEmpty) await tap(sessionTile);
    await go('/topics');
    await shot('07_topics');
    await go('/topic/fl_widgets');
    await shot('08_topic');
    await go('/stats');
    await shot('09_stats');
    await go('/profile');
    await shot('10_profile');
    await go('/plans');
    await shot('11_plans');
    await go('/pomodoro');
    await shot('12_pomodoro');
    await go('/notes');
    await shot('13_notes');
    await go('/session/30');
    await shot('14_session');
    await go('/plan/settings');
    await shot('15_plan_settings');

    // Онбординг нового плана.
    await go('/onboarding');
    await shot('16_direction');
    await tap(find.byKey(const Key('direction_python')));
    await tap(find.byKey(const Key('option_1')));
    await shot('17_diagnostic');
    await tap(find.byKey(const Key('test_skip')));
    await shot('18_schedule');
    await tap(find.byKey(const Key('schedule_generate')));
    await shot('19_preview');

    // Тёмная тема.
    await go('/profile');
    await tap(find.text('Тёмная'));
    await go('/home');
    await shot('20_home_dark');
    await go('/stats');
    await shot('21_stats_dark');
    await go('/profile');
    await tap(find.text('Светлая'));

    // Окно Windows и телефон в горизонтальной ориентации.
    await setSize(desktopSize);
    await go('/home');
    await shot('22_desktop_home');
    await go('/plan');
    await shot('23_desktop_plan');
    await setSize(phoneLandscapeSize);
    await go('/stats');
    await shot('24_landscape_stats');

    // Удаление аккаунта: диалог с ошибкой неверного пароля.
    await setSize(phoneSize);
    await go('/profile');
    await tap(find.byKey(const Key('delete_account_button')));
    await tester.enterText(
      find.byKey(const Key('delete_password_field')),
      'wrong123',
    );
    await tap(find.byKey(const Key('delete_account_confirm')));
    await shot('25_delete_account');
    await tap(find.text('Отмена'));

    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.runAsync(db.close);
    debugDisableShadows = true;
  });
}
