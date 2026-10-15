// Точка входа приложения на iPhone: запускает движок Flutter и подключает
// плагины. Здесь же настраиваются локальные уведомления (напоминания о
// занятиях) по инструкции плагина flutter_local_notifications.
import Flutter
import UIKit
// Нужен для вызова FlutterLocalNotificationsPlugin.setPluginRegistrantCallback.
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Уведомления приходят через этот объект: так iOS показывает
    // напоминание, даже когда приложение открыто.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // Плагин уведомлений сможет обращаться к остальным плагинам, когда
    // обрабатывает нажатие на уведомление в фоне.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // Подключаем все плагины (база данных, настройки, уведомления).
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
