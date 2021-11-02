//
//  BackgroundService.swift
//  flutter_foreground_task
//
//  Created by WOO JIN HWANG on 2021/08/11.
//

import Flutter
import Foundation
import UserNotifications

@available(iOS 10.0, *)
class BackgroundService: NSObject, UNUserNotificationCenterDelegate {
  static let sharedInstance = BackgroundService()
  
  var isRunningService: Bool = false
  
  private let userNotificationCenter: UNUserNotificationCenter
  private var isGrantedNotificationAuthorization: Bool = false
  
  private var notificationContentTitle: String = ""
  private var notificationContentText: String = ""
  private var showNotification: Bool = true
  private var playSound: Bool = false
  private var taskInterval: Int = 5000
  
  private var flutterEngine: FlutterEngine? = nil
  private var backgroundChannel: FlutterMethodChannel? = nil
  private var backgroundTaskTimer: Timer? = nil
  
  override init() {
    userNotificationCenter = UNUserNotificationCenter.current()
    super.init()
    userNotificationCenter.delegate = self
  }
  
  func run(action: BackgroundServiceAction) {
    let prefs = UserDefaults.standard
    
    notificationContentTitle = prefs.string(forKey: NOTIFICATION_CONTENT_TITLE) ?? notificationContentTitle
    notificationContentText = prefs.string(forKey: NOTIFICATION_CONTENT_TEXT) ?? notificationContentText
    showNotification = prefs.bool(forKey: SHOW_NOTIFICATION)
    playSound = prefs.bool(forKey: PLAY_SOUND)
    taskInterval = prefs.integer(forKey: TASK_INTERVAL)
    
    switch action {
      case .START:
        requestNotificationAuthorization()
        isRunningService = true
        if let callbackHandle = prefs.object(forKey: CALLBACK_HANDLE) as? Int64 {
          executeDartCallback(callbackHandle: callbackHandle)
        }
        break
      case .RESTART:
        sendNotification()
        isRunningService = true
        if let callbackHandle = prefs.object(forKey: CALLBACK_HANDLE_ON_RESTART) as? Int64 {
          executeDartCallback(callbackHandle: callbackHandle)
        }
        break
      case .UPDATE:
        sendNotification()
        isRunningService = true
        if let callbackHandle = prefs.object(forKey: CALLBACK_HANDLE) as? Int64 {
          executeDartCallback(callbackHandle: callbackHandle)
        }
        break
      case .STOP:
        destroyBackgroundTask() { _ in
          self.isRunningService = false
          self.isGrantedNotificationAuthorization = false
          self.removeAllNotification()
        }
        break
    }
  }
  
  private func requestNotificationAuthorization() {
    if showNotification {
      let options = UNAuthorizationOptions(arrayLiteral: .alert, .sound)
      userNotificationCenter.requestAuthorization(options: options) { success, error in
        if let error = error {
          print("Authorization error: \(error)")
        } else {
          if (success) {
            self.isGrantedNotificationAuthorization = true
            self.sendNotification()
          } else {
            print("Notification authorization denied.")
          }
        }
      }
    }
  }
  
  private func sendNotification() {
    if isGrantedNotificationAuthorization && showNotification {
      let notificationContent = UNMutableNotificationContent()
      notificationContent.title = notificationContentTitle
      notificationContent.body = notificationContentText
      if playSound {
        notificationContent.sound = UNNotificationSound.default
      }
      
      let request = UNNotificationRequest(identifier: "BackgroundNotification", content: notificationContent, trigger: nil)
      userNotificationCenter.add(request, withCompletionHandler: nil)
    }
  }
  
  private func removeAllNotification() {
    userNotificationCenter.removeAllPendingNotificationRequests()
    userNotificationCenter.removeAllDeliveredNotifications()
  }
  
  private func executeDartCallback(callbackHandle: Int64) {
    // If there is an already initialized background task, destroy it and perform initialization.
    destroyBackgroundTask() { _ in
      // The backgroundChannel cannot be registered unless the registerPlugins function is called.
      if (SwiftFlutterForegroundTaskPlugin.registerPlugins == nil) { return }
      
      self.flutterEngine = FlutterEngine(name: "BackgroundIsolate", project: nil, allowHeadlessExecution: true)
      
      let callbackInfo = FlutterCallbackCache.lookupCallbackInformation(callbackHandle)
      let entrypoint = callbackInfo?.callbackName
      let uri = callbackInfo?.callbackLibraryPath
      self.flutterEngine?.run(withEntrypoint: entrypoint, libraryURI: uri)
      
      SwiftFlutterForegroundTaskPlugin.registerPlugins!(self.flutterEngine!)
      
      let backgroundMessenger = self.flutterEngine!.binaryMessenger
      self.backgroundChannel = FlutterMethodChannel(name: "flutter_foreground_task/background", binaryMessenger: backgroundMessenger)
      self.backgroundChannel?.setMethodCallHandler(self.onMethodCall)
    }
  }
  
  private func startBackgroundTask() {
    if backgroundTaskTimer != nil { stopBackgroundTask() }
    
    backgroundChannel?.invokeMethod("start", arguments: nil) { _ in
      let timeInterval = TimeInterval(self.taskInterval / 1000)
      self.backgroundTaskTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
        self.backgroundChannel?.invokeMethod("event", arguments: nil)
      }
    }
  }
  
  private func stopBackgroundTask() {
    backgroundTaskTimer?.invalidate()
    backgroundTaskTimer = nil
  }
  
  private func destroyBackgroundTask(onComplete: @escaping (Bool) -> Void) {
    stopBackgroundTask()
    
    // The background task destruction is complete and a new background task can be started.
    if backgroundChannel == nil {
      onComplete(true)
    } else {
      backgroundChannel?.invokeMethod("destroy", arguments: nil) { _ in
        self.flutterEngine?.destroyContext()
        self.flutterEngine = nil
        self.backgroundChannel = nil
        onComplete(true)
      }
    }
  }
  
  private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "initialize":
        startBackgroundTask()
      default:
        result(FlutterMethodNotImplemented)
    }
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    completionHandler()
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if playSound {
      completionHandler([.alert, .sound])
    } else {
      completionHandler([.alert])
    }
  }
}
