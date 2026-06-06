import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let nativeNotifications = NativeNotificationBridge()
  private let universalLinks = NativeUniversalLinkBridge.shared

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
      nativeNotifications.setInitial(payload: notification)
    }
    if let url = launchOptions?[.url] as? URL {
      universalLinks.setInitial(url: url.absoluteString)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "NativeNotificationBridge") {
      nativeNotifications.attach(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "NativeUniversalLinkBridge") {
      universalLinks.attach(messenger: registrar.messenger())
    }
  }

  override func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    universalLinks.publish(url: url.absoluteString)
    return super.application(application, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      universalLinks.publish(url: url.absoluteString)
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    nativeNotifications.setDeviceToken(deviceToken)
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    nativeNotifications.publish(payload: userInfo)
    completionHandler(.newData)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    nativeNotifications.publish(payload: response.notification.request.content.userInfo)
    completionHandler()
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    nativeNotifications.publish(payload: notification.request.content.userInfo)
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}

final class NativeUniversalLinkBridge: NSObject, FlutterStreamHandler {
  static let shared = NativeUniversalLinkBridge()

  private let methodChannelName = "khuctamgiao/universal_links"
  private let eventChannelName = "khuctamgiao/universal_links/events"
  private var initialUrl: String?
  private var eventSink: FlutterEventSink?

  func attach(messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: messenger)
    methodChannel.setMethodCallHandler(handleMethodCall)

    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: messenger)
    eventChannel.setStreamHandler(self)
  }

  func setInitial(url: String) {
    initialUrl = url
  }

  func publish(url: String) {
    if let eventSink {
      eventSink(url)
    } else {
      initialUrl = url
    }
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getInitialLink":
      result(initialUrl)
    case "clearInitialLink":
      initialUrl = nil
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class NativeNotificationBridge: NSObject, FlutterStreamHandler {
  private let methodChannelName = "khuctamgiao/notifications"
  private let eventChannelName = "khuctamgiao/notifications/events"
  private var initialPayload: [String: Any]?
  private var eventSink: FlutterEventSink?
  private var deviceToken: String?

  func attach(messenger: FlutterBinaryMessenger) {
    let methodChannel = FlutterMethodChannel(
      name: methodChannelName,
      binaryMessenger: messenger)
    methodChannel.setMethodCallHandler(handleMethodCall)

    let eventChannel = FlutterEventChannel(
      name: eventChannelName,
      binaryMessenger: messenger)
    eventChannel.setStreamHandler(self)
  }

  func setInitial(payload: [AnyHashable: Any]) {
    initialPayload = normalize(payload: payload)
  }

  func publish(payload: [AnyHashable: Any]) {
    let normalized = normalize(payload: payload)
    if let eventSink {
      eventSink(normalized)
    } else {
      initialPayload = normalized
    }
  }

  func setDeviceToken(_ token: Data) {
    deviceToken = token.map { String(format: "%02.2hhx", $0) }.joined()
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getInitialNotification":
      result(initialPayload)
    case "clearInitialNotification":
      initialPayload = nil
      result(nil)
    case "requestPermission":
      requestPermission(result: result)
    case "areNotificationsEnabled":
      areNotificationsEnabled(result: result)
    case "openNotificationSettings":
      openNotificationSettings(result: result)
    case "getDeviceToken":
      result(deviceToken)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func requestPermission(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, _ in
      if granted {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
      result(granted)
    }
  }

  private func areNotificationsEnabled(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      let enabled = settings.authorizationStatus == .authorized ||
        settings.authorizationStatus == .provisional ||
        {
          if #available(iOS 14.0, *) {
            return settings.authorizationStatus == .ephemeral
          }
          return false
        }()
      result(enabled)
    }
  }

  private func openNotificationSettings(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      if let url = URL(string: UIApplication.openSettingsURLString),
         UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
      }
      result(nil)
    }
  }

  private func normalize(payload: [AnyHashable: Any]) -> [String: Any] {
    var normalized: [String: Any] = [:]
    for (key, value) in payload {
      let stringKey = String(describing: key)
      if let value = value as? String {
        normalized[stringKey] = value
      } else if let value = value as? NSNumber {
        normalized[stringKey] = value
      } else if let nested = value as? [AnyHashable: Any] {
        for (nestedKey, nestedValue) in nested {
          if let nestedValue = nestedValue as? String {
            normalized["\(stringKey).\(String(describing: nestedKey))"] = nestedValue
          }
        }
      }
    }
    if normalized["url"] == nil {
      normalized["url"] = normalized["data.url"] ?? normalized["data_url"]
    }
    return normalized
  }
}
