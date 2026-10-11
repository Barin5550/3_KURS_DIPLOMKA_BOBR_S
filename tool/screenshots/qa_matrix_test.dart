// Визуальная проверка всех экранов перед сдачей.
//
// Запуск:  flutter test tool/screenshots/qa_matrix_test.dart
// Результат: build/qa_screens/<конфигурация>/<экран>.png и список ошибок
// вёрстки (переполнений) в build/qa_screens/errors.txt.
//
// Каждый экран снимается в нескольких конфигурациях: светлая и тёмная тема,
// телефон, маленький телефон, крупный шрифт, горизонтальная ориентация
// и окно компьютера.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:marshrut/app.dart';
import 'package:marshrut/presentation/providers/providers.dart';
import 'package:marshrut/presentation/screens/auth/register_screen.dart';
import 'package:marshrut/presentation/screens/onboarding/diagnostic_screen.dart';
import 'package:marshrut/presentation/screens/onboarding/direction_screen.dart';
import 'package:marshrut/presentation/screens/onboarding/schedule_screen.dart';
import 'package:marshrut/presentation/screens/profile/profile_screen.dart';

import '../../test/helpers/test_app.dart';
import 'screenshot_support.dart';

const _outDir = 'build/qa_screens';
const _ratio = 2.0;
final _boundary = GlobalKey();

class _Config {
  const _Config(this.name, this.size, this.theme, {this.textScale = 1.0});
  final String name;
  final Size size;
  final String theme;
  final double textScale;
}

const _configs = [
  _Config('phone_light', phoneSize, 'light'),
  _Config('phone_dark', phoneSize, 'dark'),
  _Config('small_light', Size(360, 640), 'light'),
  _Config('big_font_light', phoneSize, 'light', textScale: 1.3),
  _Config('landscape_dark', phoneLandscapeSize, 'dark'),
  _Config('desktop_light', desktopSize, 'light'),
  _Config('desktop_dark', desktopSize, 'dark'),
];

const _loggedInRoutes = {
  'home': '/home',
  'plan': '/plan',
  'topics': '/topics',
  'topic': '/topic/fl_widgets',
  'topic_custom': '/topic/custom_1',
  'topic_custom_edit': '/topics/custom/custom_1',
  'topic_custom_new': '/topics/custom/new?direction=flutter',
  'stats': '/stats',
  'profile': '/profile',
  'profile_edit': '/profile/edit',
  'profile_password': '/profile/password',
  'plans': '/plans',
  'plan_settings': '/plan/settings',
  'pomodoro': '/pomodoro?topic=Виджеты',
  'notes': '/notes',
  'note_edit': '/notes/edit?id=1',
  'note_new': '/notes/edit',
  'session_done': '/session/3',
  'session_review': '/session/30',
};

/// Длинные экраны: дополнительно снимается их конец.
const _longScreens = {
  'home',
  'stats',
  'profile',
  'plan_settings',
  'topic_custom_edit',
  'session_review',
};

void main() {
  testWidgets(
    'матрица скриншотов для проверки',
    timeout: const Timeout(Duration(minutes: 30)),
    (tester) async {
      debugDisableShadows = false;
      await tester.runAsync(loadScreenshotFonts);
      final out = Directory(_outDir);
      if (out.existsSync()) out.deleteSync(recursive: true);
      out.createSync(recursive: true);

      var current = '';
      final errors = <String>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final text = details.exceptionAsString().split('\n').first;
        errors.add('$current: $text');
      };

      final db = memoryDatabase();
      await tester.runAsync(() => seedDemoUser(db));
      final overrides = await tester.runAsync(() => testOverrides(db: db));

      Future<void> configure(_Config c) async {
        tester.view.devicePixelRatio = _ratio;
        tester.view.physicalSize = c.size * _ratio;
        tester.platformDispatcher.textScaleFactorTestValue = c.textScale;
        await tester.pump();
      }

      await configure(_configs.first);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _boundary,
          child: ProviderScope(
            overrides: overrides!,
            child: const MarshrutApp(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1800));
      await settle(tester);

      ProviderContainer container() => ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );

      Future<void> setTheme(String mode) async {
        await tester.runAsync(
          () => container().read(themeModeProvider.notifier).set(mode),
        );
        await settle(tester, rounds: 3);
      }

      Future<void> shot(String config, String name) async {
        current = '$config/$name';
        await settle(tester, rounds: 6);
        final boundary =
            _boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final bytes = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: _ratio);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          return data!.buffer.asUint8List();
        });
        Directory('$_outDir/$config').createSync(recursive: true);
        File('$_outDir/$config/$name.png').writeAsBytesSync(bytes!);
      }

      Future<void> go(String location) async {
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
        await settle(tester);
      }

      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        // Без кадра после прокрутки tap() берёт старые координаты.
        await tester.pump();
        await tester.tap(finder);
        await settle(tester);
      }

      /// Нажатие на элемент экрана [screen], при необходимости с прокруткой.
      Future<void> tapIn(Type screen, Key key) async {
        final finder = find.byKey(key);
        if (finder.evaluate().isEmpty) {
          await tester.scrollUntilVisible(
            finder,
            200,
            scrollable: find
                .descendant(
                  of: find.byType(screen),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
        }
        await tap(finder);
      }

      /// Прокрутка основного (самого большого вертикального) списка до конца.
      Future<void> scrollToEnd() async {
        for (var i = 0; i < 3; i++) {
          final states = find
              .byType(Scrollable)
              .evaluate()
              .map((e) => (e as StatefulElement).state as ScrollableState)
              .where((st) => st.position.axis == Axis.vertical)
              .toList();
          if (states.isEmpty) return;
          states.sort(
            (a, b) => b.position.viewportDimension.compareTo(
              a.position.viewportDimension,
            ),
          );
          final position = states.first.position;
          position.jumpTo(position.maxScrollExtent);
          await settle(tester, rounds: 2);
        }
      }

      // Ошибка на одном шаге не останавливает проверку остальных экранов.
      Future<void> step(String name, Future<void> Function() body) async {
        try {
          await body();
        } on Object catch (e) {
          errors.add('$name: шаг не выполнен: ${'$e'.split('\n').first}');
        }
      }

      Future<void> login(String email, String password) async {
        await go('/login');
        await tester.enterText(find.byKey(const Key('login_email')), email);
        await tester.enterText(
          find.byKey(const Key('login_password')),
          password,
        );
        await tap(find.byKey(const Key('login_submit')));
      }

      try {
        // Экраны без входа.
        for (final c in _configs) {
          await configure(c);
          await setTheme(c.theme);
          await step('${c.name}/auth', () async {
            await go('/login');
            await shot(c.name, 'login');
            await go('/register');
            await shot(c.name, 'register');
            await tapIn(RegisterScreen, const Key('reg_submit'));
            await shot(c.name, 'register_errors');
          });
        }

        await configure(_configs.first);
        await login('aliya@mail.ru', 'flutter2026');

        for (final c in _configs) {
          await configure(c);
          await setTheme(c.theme);
          for (final MapEntry(key: name, value: route)
              in _loggedInRoutes.entries) {
            await step('${c.name}/$name', () async {
              await go(route);
              await shot(c.name, name);
              if (_longScreens.contains(name)) {
                await scrollToEnd();
                await shot(c.name, '${name}_end');
              }
            });
          }

          await step('${c.name}/onboarding', () async {
            await go('/onboarding');
            await shot(c.name, 'onb_1_direction');
            await tapIn(DirectionScreen, const Key('direction_python'));
            await shot(c.name, 'onb_2_test');
            await tapIn(DiagnosticScreen, const Key('test_skip'));
            await shot(c.name, 'onb_3_schedule');
            await tapIn(ScheduleScreen, const Key('schedule_generate'));
            await shot(c.name, 'onb_4_preview');
            await scrollToEnd();
            await shot(c.name, 'onb_4_preview_end');
          });

          await step('${c.name}/delete_dialog', () async {
            await go('/profile');
            await tapIn(ProfileScreen, const Key('delete_account_button'));
            await shot(c.name, 'dialog_delete_account');
            await tap(find.text('Отмена'));
          });
        }

        // Новый пользователь без планов и данных: пустые состояния.
        await tester.runAsync(
          () => testAuthRepository(db).register(
            name: 'Новый',
            email: 'new@mail.ru',
            password: 'flutter2026',
          ),
        );
        await tester.runAsync(
          () => container().read(authControllerProvider.notifier).logout(),
        );
        await settle(tester);
        await configure(_configs.first);
        await login('new@mail.ru', 'flutter2026');
        for (final c in _configs) {
          await configure(c);
          await setTheme(c.theme);
          for (final name in [
            'home',
            'plan',
            'topics',
            'stats',
            'notes',
            'plans',
          ]) {
            await step('${c.name}/empty_$name', () async {
              await go(_loggedInRoutes[name]!);
              await shot(c.name, 'empty_$name');
            });
          }
        }
      } finally {
        File('$_outDir/errors.txt').writeAsStringSync(errors.join('\n'));
        FlutterError.onError = originalOnError;
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      }

      await tester.pumpWidget(const SizedBox());
      await settle(tester);
      await tester.runAsync(db.close);
      debugDisableShadows = true;
    },
  );
}
