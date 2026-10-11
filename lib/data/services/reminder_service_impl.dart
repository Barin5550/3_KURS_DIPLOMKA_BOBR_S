import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/repositories/repositories.dart';

/// Ежедневные напоминания через flutter_local_notifications.
///
/// Время напоминания переводится в UTC, поэтому дополнительный пакет для
/// определения часового пояса устройства не нужен.
///
/// На Android и iOS работают и ежедневные напоминания, и мгновенные
/// уведомления. В Windows плагин не умеет повторять уведомление каждый день
/// и отменять его в приложении без MSIX-установщика, поэтому там доступны
/// только мгновенные уведомления (например, окончание «помидора»).
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
    windows: WindowsNotificationDetails(),
  );

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  @override
  bool get supportsDailyReminders => _isMobile;

  @override
  Future<void> init() async {
    if (_initialized || !(_isMobile || _isWindows)) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        windows: WindowsInitializationSettings(
          appName: 'Маршрут',
          appUserModelId: 'Barin.Marshrut',
          guid: 'ae2dc08a-b972-4caf-92da-cfa489d2bc16',
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    if (!supportsDailyReminders) return false;
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
    if (!supportsDailyReminders) return;
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
    if (!supportsDailyReminders) return;
    await init();
    await _plugin.cancel(id: _dailyId);
  }

  @override
  Future<void> showNow({required String title, required String body}) async {
    if (!(_isMobile || _isWindows)) return;
    try {
      await init();
      await _plugin.show(
        id: _instantId,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } on Object catch (e) {
      // Уведомление — дополнительная функция: сбой платформы не роняет экран.
      debugPrint('Уведомление не показано: $e');
    }
  }
}

/// Пустая реализация для тестов и платформ без уведомлений.
class NoopReminderService implements ReminderService {
  NoopReminderService({this.supportsDailyReminders = true});

  @override
  final bool supportsDailyReminders;

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
