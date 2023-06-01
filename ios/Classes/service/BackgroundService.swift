//
//  BackgroundService.swift
//  flutter_foreground_task
//
//  Created by WOO JIN HWANG on 2021/08/11.
//

import Flutter
import Foundation
import UserNotifications

let NOTIFICATION_ID: String = "flutter_foreground_task/backgroundNotification"
let BG_ISOLATE_NAME: String = "flutter_foreground_task/backgroundIsolate"
let BG_CHANNEL_NAME: String = "flutter_foreground_task/background"

let ACTION_TASK_START: String = "onStart"
let ACTION_TASK_REPEAT_EVENT: String = "onRepeatEvent"
let ACTION_TASK_DESTROY: String = "onDestroy"

@available(iOS 10.0, *)
class BackgroundService: NSObject {
  static let sharedInstance = BackgroundService()
  
  var isRunningService: Bool = false
  
  private let userNotificationCenter: UNUserNotificationCenter
  private var isGrantedNotificationAuthorization: Bool = false
  
  private var notificationContentTitle: String = ""
  private var notificationContentText: String = ""
  private var showNotification: Bool = true
  private var playSound: Bool = false
  private var prevInterval: Int? = nil
  private var currInterval: Int = 5000
  private var prevIsOnceEvent: Bool? = nil
  private var currIsOnceEvent: Bool = false
  private var prevCallbackHandle: Int64? = nil
  private var currCallbackHandle: Int64? = nil
  
  private var flutterEngine: FlutterEngine? = nil
  private var backgroundChannel: FlutterMethodChannel? = nil
  private var repeatTask: Timer? = nil
  
  override init() {
    userNotificationCenter = UNUserNotificationCenter.current()
    super.init()
    // userNotificationCenter.delegate = self
  }
  
  func run(action: BackgroundServiceAction) {
    let prefs = UserDefaults.standard
    
    notificationContentTitle = prefs.string(forKey: NOTIFICATION_CONTENT_TITLE) ?? notificationContentTitle
    notificationContentText = prefs.string(forKey: NOTIFICATION_CONTENT_TEXT) ?? notificationContentText
    showNotification = prefs.bool(forKey: SHOW_NOTIFICATION)
    playSound = prefs.bool(forKey: PLAY_SOUND)
    prevInterval = currInterval
    currInterval = prefs.integer(forKey: TASK_INTERVAL)
    prevIsOnceEvent = currIsOnceEvent
    currIsOnceEvent = prefs.bool(forKey: IS_ONCE_EVENT)
    prevCallbackHandle = currCallbackHandle
    currCallbackHandle = prefs.object(forKey: CALLBACK_HANDLE) as? Int64
    
    switch action {
      case .START:
        requestNotificationAuthorization()
        isRunningService = true
        if let callbackHandle = currCallbackHandle {
          executeDartCallback(callbackHandle: callbackHandle)
        }
        break
      case .RESTART:
        sendNotification()
        isRunningService = true
        if let callbackHandle = currCallbackHandle {
          executeDartCallback(callbackHandle: callbackHandle)
        }
        break
      case .UPDATE:
        sendNotification()
        isRunningService = true
        if let callbackHandle = currCallbackHandle {
          if prevCallbackHandle != callbackHandle {
            executeDartCallback(callbackHandle: callbackHandle)
          } else {
            if prevInterval != currInterval || prevIsOnceEvent != currIsOnceEvent {
              startRepeatTask()
            }
          }
        }
        break
      case .STOP:
        stopBackgroundTask() { _ in
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
      
      let request = UNNotificationRequest(identifier: NOTIFICATION_ID, content: notificationContent, trigger: nil)
      userNotificationCenter.add(request, withCompletionHandler: nil)
    }
  }
  
  private func removeAllNotification() {
    userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [NOTIFICATION_ID])
    userNotificationCenter.removeDeliveredNotifications(withIdentifiers: [NOTIFICATION_ID])
  }
  
  private func executeDartCallback(callbackHandle: Int64) {
    stopBackgroundTask() { _ in
      // The backgroundChannel cannot be registered unless the registerPlugins function is called.
      if (SwiftFlutterForegroundTaskPlugin.registerPlugins == nil) { return }
      
      self.flutterEngine = FlutterEngine(name: BG_ISOLATE_NAME, project: nil, allowHeadlessExecution: true)
      
      let callbackInfo = FlutterCallbackCache.lookupCallbackInformation(callbackHandle)
      let entrypoint = callbackInfo?.callbackName
      let uri = callbackInfo?.callbackLibraryPath
      self.flutterEngine?.run(withEntrypoint: entrypoint, libraryURI: uri)
      
      SwiftFlutterForegroundTaskPlugin.registerPlugins!(self.flutterEngine!)
      
      let backgroundMessenger = self.flutterEngine!.binaryMessenger
      self.backgroundChannel = FlutterMethodChannel(name: BG_CHANNEL_NAME, binaryMessenger: backgroundMessenger)
      self.backgroundChannel?.setMethodCallHandler(self.onMethodCall)
    }
  }
  
  private func startBackgroundTask() {
    stopRepeatTask()
    
    backgroundChannel?.invokeMethod(ACTION_TASK_START, arguments: nil) { _ in
      self.startRepeatTask()
    }
  }
  
  private func startRepeatTask() {
    stopRepeatTask()
    
    if currIsOnceEvent {
      backgroundChannel?.invokeMethod(ACTION_TASK_REPEAT_EVENT, arguments: nil)
      return
    }
    
    let timeInterval = TimeInterval(currInterval / 1000)
    repeatTask = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
      self.backgroundChannel?.invokeMethod(ACTION_TASK_REPEAT_EVENT, arguments: nil)
    }
  }
  
  private func stopRepeatTask() {
    repeatTask?.invalidate()
    repeatTask = nil
  }
  
  private func stopBackgroundTask(onComplete: @escaping (Bool) -> Void) {
    stopRepeatTask()
    
    // The background task destruction is complete and a new background task can be started.
    if backgroundChannel == nil {
      onComplete(true)
    } else {
      backgroundChannel?.invokeMethod(ACTION_TASK_DESTROY, arguments: nil) { _ in
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
    // If it is not a notification requested by this plugin, the processing below is ignored.
    if response.notification.request.identifier != NOTIFICATION_ID { return }
    
    completionHandler()
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // If it is not a notification requested by this plugin, the processing below is ignored.
    if notification.request.identifier != NOTIFICATION_ID { return }
    
    if playSound {
      completionHandler([.alert, .sound])
    } else {
      completionHandler([.alert])
    }
  }
}
