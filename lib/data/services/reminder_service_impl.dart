// Сервис уведомлений (слой data).
// Реализует интерфейс ReminderService из слоя domain: ежедневное напоминание
// об учёбе и мгновенные уведомления (например, конец «помидора»).
// LocalReminderService создаётся в reminderServiceProvider и вызывается из
// AuthController и экрана Pomodoro; NoopReminderService — заглушка для тестов.

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/theme/app_theme.dart';
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
  /// Можно передать свой объект плагина (например, подделку в тестах);
  /// если его нет, создаётся настоящий плагин уведомлений.
  LocalReminderService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Плагин flutter_local_notifications, который показывает уведомления
  /// средствами операционной системы.
  final FlutterLocalNotificationsPlugin _plugin;

  /// Флаг: плагин уже настроен, повторно вызывать [init] не нужно.
  bool _initialized = false;

  /// Номер ежедневного напоминания (по нему его можно заменить или отменить).
  static const _dailyId = 1;

  /// Номер мгновенного уведомления.
  static const _instantId = 2;

  /// Внешний вид уведомления для каждой платформы.
  static const _details = NotificationDetails(
    // Android: канал уведомлений (его название видно в настройках телефона)
    // с высокой важностью, чтобы уведомление всплывало на экране.
    android: AndroidNotificationDetails(
      'study_reminders',
      'Напоминания о занятиях',
      channelDescription: 'Ежедневное напоминание о плане обучения',
      importance: Importance.high,
      priority: Priority.high,
      // Белый силуэт логотипа в строке состояния и оранжевый акцент.
      icon: 'ic_stat_marshrut',
      color: AppColors.orange,
    ),
    // iOS и Windows: настройки по умолчанию.
    iOS: DarwinNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );

  /// `true` на Android и iOS (в браузере — всегда `false`).
  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// `true`, если приложение запущено в Windows (не в браузере).
  bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  /// Ежедневные напоминания доступны только на телефонах (см. описание
  /// класса). По этому флагу экран профиля делает переключатель
  /// напоминания активным или неактивным.
  @override
  bool get supportsDailyReminders => _isMobile;

  /// Настраивает плагин один раз. На неподдерживаемых платформах
  /// (веб, Linux, macOS) ничего не делает.
  @override
  Future<void> init() async {
    // Уже настроен или платформа без уведомлений — выходим.
    if (_initialized || !(_isMobile || _isWindows)) return;
    // Загружаем базу часовых поясов (нужна для zonedSchedule).
    tzdata.initializeTimeZones();
    // Передаём плагину настройки для каждой платформы.
    await _plugin.initialize(
      settings: const InitializationSettings(
        // Android: значок уведомления по умолчанию.
        android: AndroidInitializationSettings('ic_stat_marshrut'),
        // iOS: разрешение не запрашиваем при запуске — только когда
        // пользователь включает напоминание в профиле (requestPermission).
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        // Windows: название приложения и его постоянные идентификаторы,
        // по которым система узнаёт отправителя уведомлений.
        windows: WindowsInitializationSettings(
          appName: 'Маршрут',
          appUserModelId: 'Barin.Marshrut',
          guid: 'ae2dc08a-b972-4caf-92da-cfa489d2bc16',
        ),
      ),
    );
    _initialized = true;
  }

  /// Спрашивает у пользователя разрешение на уведомления.
  /// Возвращает `true`, если разрешение дано.
  @override
  Future<bool> requestPermission() async {
    // Без ежедневных напоминаний разрешение не нужно.
    if (!supportsDailyReminders) return false;
    await init();
    // Пробуем получить Android-часть плагина (на iOS будет null).
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // На Android запрашиваем разрешение через системный диалог.
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    // Иначе это iOS: просим разрешение на баннеры и звук.
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  /// Ставит ежедневное напоминание на [hour]:[minute] по местному времени.
  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!supportsDailyReminders) return;
    await init();
    // Ближайший момент с нужным временем: сегодня...
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute);
    // ...а если это время сегодня уже прошло — завтра.
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    // Планируем уведомление; при повторном вызове оно заменит старое,
    // потому что номер (_dailyId) тот же.
    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'Время учиться 📚',
      body: 'Откройте «Маршрут»: задачи на сегодня уже ждут.',
      // Местное время переводим в UTC (см. описание класса).
      scheduledDate: tz.TZDateTime.from(next.toUtc(), tz.UTC),
      notificationDetails: _details,
      // Неточный режим: не нужно особое разрешение Android на точные
      // будильники; AllowWhileIdle — срабатывает и в режиме простоя.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      // Повторять каждый день в то же время.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Отменяет ежедневное напоминание.
  @override
  Future<void> cancelDailyReminder() async {
    if (!supportsDailyReminders) return;
    await init();
    await _plugin.cancel(id: _dailyId);
  }

  /// Сразу показывает уведомление с заголовком [title] и текстом [body].
  @override
  Future<void> showNow({required String title, required String body}) async {
    // На платформах без уведомлений просто ничего не делаем.
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
///
/// Ничего не показывает, а только записывает вызовы в [log], чтобы тест
/// мог проверить, что напоминание было поставлено или отменено.
class NoopReminderService implements ReminderService {
  /// [supportsDailyReminders] можно выключить, чтобы проверить экран
  /// на платформе без ежедневных напоминаний.
  NoopReminderService({this.supportsDailyReminders = true});

  /// Делает вид, что ежедневные напоминания поддерживаются (или нет).
  @override
  final bool supportsDailyReminders;

  /// Журнал вызовов: «schedule 9:0», «cancel», «show …».
  final List<String> log = [];

  /// Настраивать нечего.
  @override
  Future<void> init() async {}

  /// Разрешение всегда «дано».
  @override
  Future<bool> requestPermission() async => true;

  /// Записывает в журнал время напоминания.
  @override
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async => log.add('schedule $hour:$minute');

  /// Записывает в журнал отмену напоминания.
  @override
  Future<void> cancelDailyReminder() async => log.add('cancel');

  /// Записывает в журнал заголовок уведомления.
  @override
  Future<void> showNow({required String title, required String body}) async =>
      log.add('show $title');
}
