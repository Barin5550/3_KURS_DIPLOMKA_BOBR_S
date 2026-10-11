import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/repositories/repositories.dart';

/// Ежедневные напоминания через flutter_local_notifications.
///
/// Время напоминания переводится в UTC, поэтому дополнительный пакет для
/// определения часового пояса устройства не нужен.
class LocalReminderService implements ReminderService {
  LocalReminderService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const _dailyId = 1;
  static const _instantId = 2;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'study_reminders',
      'Напоминания о занятиях',
      channelDescription: 'Ежедневное напоминание о плане обучения',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> init() async {
    if (_initialized || !_supported) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await init();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_supported) return;
    await init();
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'Время учиться 📚',
      body: 'Откройте «Маршрут»: задачи на сегодня уже ждут.',
      scheduledDate: tz.TZDateTime.from(next.toUtc(), tz.UTC),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    if (!_supported) return;
    await init();
    await _plugin.cancel(id: _dailyId);
  }

  @override
  Future<void> showNow({required String title, required String body}) async {
    if (!_supported) return;
    await init();
    await _plugin.show(
      id: _instantId,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }
}

/// Пустая реализация для тестов и платформ без уведомлений.
class NoopReminderService implements ReminderService {
  final List<String> log = [];

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async => log.add('schedule $hour:$minute');

  @override
  Future<void> cancelDailyReminder() async => log.add('cancel');

  @override
  Future<void> showNow({required String title, required String body}) async =>
      log.add('show $title');
}
