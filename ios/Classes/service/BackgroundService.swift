//
//  BackgroundService.swift
//  flutter_foreground_task
//
//  Created by WOO JIN HWANG on 2021/08/11.
//

import Flutter
import Foundation
import UserNotifications

let NOTIFICATION_ID: String = "flutter_foreground_task/notification"
let NOTIFICATION_CATEGORY_ID: String = "flutter_foreground_task/notification_category"
let BG_ISOLATE_NAME: String = "flutter_foreground_task/backgroundIsolate"
let BG_CHANNEL_NAME: String = "flutter_foreground_task/background"

let ACTION_TASK_START: String = "onStart"
let ACTION_TASK_REPEAT_EVENT: String = "onRepeatEvent"
let ACTION_TASK_DESTROY: String = "onDestroy"
let ACTION_RECEIVE_DATA: String = "onReceiveData"

let ACTION_NOTIFICATION_BUTTON_PRESSED = "onNotificationButtonPressed"

@available(iOS 10.0, *)
class BackgroundService: NSObject {
  static let sharedInstance = BackgroundService()
  
  private(set) var isRunningService: Bool = false
  
  private var taskLifecycleListeners: Array<FlutterForegroundTaskLifecycleListener> = []
  
  func addTaskLifecycleListener(_ listener: FlutterForegroundTaskLifecycleListener) {
    if taskLifecycleListeners.contains(where: { $0 === listener }) == false {
      taskLifecycleListeners.append(listener)
    }
  }
  
  func removeTaskLifecycleListener(_ listener: FlutterForegroundTaskLifecycleListener) {
    if let index = taskLifecycleListeners.firstIndex(where: { $0 === listener }) {
      taskLifecycleListeners.remove(at: index)
    }
  }
  
  private var flutterEngine: FlutterEngine? = nil
  private var backgroundChannel: FlutterMethodChannel? = nil
  private var repeatTask: Timer? = nil
  
  func sendData(data: Any?) {
    if isRunningService {
      backgroundChannel?.invokeMethod(ACTION_RECEIVE_DATA, arguments: data)
    }
  }
  
  private let notificationCenter: UNUserNotificationCenter
  private var isGrantedNotificationAuthorization: Bool = false
  private var canReceiveNotificationResponse: Bool = false

  private var notificationOptions: NotificationOptions
  private var notificationContent: NotificationContent
  private var prevBackgroundTaskOptions: BackgroundTaskOptions?
  private var currBackgroundTaskOptions: BackgroundTaskOptions
  private var prevBackgroundTaskData: BackgroundTaskData?
  private var currBackgroundTaskData: BackgroundTaskData
  
  override init() {
    notificationCenter = UNUserNotificationCenter.current()
    notificationOptions = NotificationOptions.getData()
    notificationContent = NotificationContent.getData()
    currBackgroundTaskOptions = BackgroundTaskOptions.getData()
    currBackgroundTaskData = BackgroundTaskData.getData()
    super.init()
  }
  
  func run(action: BackgroundServiceAction) {
    notificationOptions = NotificationOptions.getData()
    notificationContent = NotificationContent.getData()
    prevBackgroundTaskOptions = currBackgroundTaskOptions
    currBackgroundTaskOptions = BackgroundTaskOptions.getData()
    prevBackgroundTaskData = currBackgroundTaskData
    currBackgroundTaskData = BackgroundTaskData.getData()
    
    switch action {
      case .START:
        requestNotificationAuthorization()
        isRunningService = true
        if let callbackHandle = currBackgroundTaskData.callbackHandle {
          executeDartCallback(callbackHandle: callbackHandle)
        }
        break
      case .RESTART:
        requestNotification()
        isRunningService = true
        if let callbackHandle = currBackgroundTaskData.callbackHandle {
          executeDartCallback(callbackHandle: callbackHandle)
        }
        break
      case .UPDATE:
        requestNotification()
        isRunningService = true
        if let callbackHandle = currBackgroundTaskData.callbackHandle {
          if prevBackgroundTaskData?.callbackHandle != callbackHandle {
            executeDartCallback(callbackHandle: callbackHandle)
          } else {
            let prevInterval = prevBackgroundTaskOptions?.interval
            let currInterval = currBackgroundTaskOptions.interval
            let prevIsOnceEvent = prevBackgroundTaskOptions?.isOnceEvent
            let currIsOnceEvent = currBackgroundTaskOptions.isOnceEvent
            if prevInterval != currInterval || prevIsOnceEvent != currIsOnceEvent {
              startRepeatTask()
            }
          }
        }
        break
      case .STOP:
        destroyBackgroundTask() { _ in
          self.disposeBackgroundChannel()
          self.destroyFlutterEngine()
        }
        removeAllNotification()
        isGrantedNotificationAuthorization = false
        isRunningService = false
        break
    }
  }
  
  private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "startTask":
        startBackgroundTask()
      default:
        result(FlutterMethodNotImplemented)
    }
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              _ response: UNNotificationResponse,
                              _ completionHandler: @escaping () -> Void) {
    // If it is not a notification requested by this plugin, the processing below is ignored.
    if response.notification.request.identifier != NOTIFICATION_ID { return }
    
    // Prevents duplicate processing due to the `registrar.addApplicationDelegate`.
    if !canReceiveNotificationResponse { return }
    canReceiveNotificationResponse = false
    
    let actionId = response.actionIdentifier
    if notificationContent.buttons.contains(where: { $0.id == actionId }) {
      backgroundChannel?.invokeMethod(ACTION_NOTIFICATION_BUTTON_PRESSED, arguments: actionId)
    }
    
    completionHandler()
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              _ notification: UNNotification,
                              _ completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    // If it is not a notification requested by this plugin, the processing below is ignored.
    if notification.request.identifier != NOTIFICATION_ID { return }
    
    if notificationOptions.playSound {
      completionHandler([.alert, .sound])
    } else {
      completionHandler([.alert])
    }
    
    // Prevents duplicate processing due to the `registrar.addApplicationDelegate`.
    canReceiveNotificationResponse = true
  }
  
  private func requestNotificationAuthorization() {
    if notificationOptions.showNotification {
      let options = UNAuthorizationOptions(arrayLiteral: .alert, .sound)
      notificationCenter.requestAuthorization(options: options) { success, error in
        if let error = error {
          print("Authorization error: \(error)")
        } else {
          if (success) {
            self.isGrantedNotificationAuthorization = true
            self.requestNotification()
          } else {
            print("Notification authorization denied.")
          }
        }
      }
    }
  }
  
  private func requestNotification() {
    if isGrantedNotificationAuthorization && notificationOptions.showNotification {
      // set notification actions
      var actions: [UNNotificationAction] = []
      for button in notificationContent.buttons {
        let action = UNNotificationAction(identifier: button.id, title: button.text)
        actions.append(action)
      }
      
      let category = UNNotificationCategory(
        identifier: NOTIFICATION_CATEGORY_ID,
        actions: actions,
        intentIdentifiers: []
      )
      notificationCenter.setNotificationCategories([category])
      
      // request notification
      let content = UNMutableNotificationContent()
      content.title = notificationContent.title
      content.body = notificationContent.text
      content.categoryIdentifier = NOTIFICATION_CATEGORY_ID
      if notificationOptions.playSound {
        content.sound = UNNotificationSound.default
      }
      
      let request = UNNotificationRequest(identifier: NOTIFICATION_ID, content: content, trigger: nil)
      notificationCenter.add(request, withCompletionHandler: nil)
    }
  }
  
  private func removeAllNotification() {
    notificationCenter.removePendingNotificationRequests(withIdentifiers: [NOTIFICATION_ID])
    notificationCenter.removeDeliveredNotifications(withIdentifiers: [NOTIFICATION_ID])
  }
  
  private func executeDartCallback(callbackHandle: Int64) {
    destroyBackgroundTask() { _ in
      // The backgroundChannel cannot be registered unless the registerPlugins function is called.
      if (SwiftFlutterForegroundTaskPlugin.registerPlugins == nil) { return }
      
      self.destroyFlutterEngine()
      self.createFlutterEngine()
      
      let callbackInfo = FlutterCallbackCache.lookupCallbackInformation(callbackHandle)
      let entrypoint = callbackInfo?.callbackName
      let uri = callbackInfo?.callbackLibraryPath
      self.flutterEngine?.run(withEntrypoint: entrypoint, libraryURI: uri)
      
      self.disposeBackgroundChannel()
      SwiftFlutterForegroundTaskPlugin.registerPlugins!(self.flutterEngine!)
      self.createBackgroundChannel()
    }
  }
  
  private func createFlutterEngine() {
    flutterEngine = FlutterEngine(name: BG_ISOLATE_NAME, project: nil, allowHeadlessExecution: true)
    for listener in taskLifecycleListeners {
      listener.onEngineCreate(flutterEngine: flutterEngine!)
    }
  }
  
  private func destroyFlutterEngine() {
    for listener in taskLifecycleListeners {
      listener.onEngineWillDestroy()
    }
    flutterEngine?.destroyContext()
    flutterEngine = nil
  }
  
  private func createBackgroundChannel() {
    let messenger = flutterEngine!.binaryMessenger
    backgroundChannel = FlutterMethodChannel(name: BG_CHANNEL_NAME, binaryMessenger: messenger)
    backgroundChannel?.setMethodCallHandler(onMethodCall)
  }
  
  private func disposeBackgroundChannel() {
    backgroundChannel?.setMethodCallHandler(nil)
    backgroundChannel = nil
  }
  
  private func startBackgroundTask() {
    stopRepeatTask()
    
    backgroundChannel?.invokeMethod(ACTION_TASK_START, arguments: nil) { _ in
      self.startRepeatTask()
      for listener in self.taskLifecycleListeners {
        listener.onTaskStart()
      }
    }
  }
  
  private func destroyBackgroundTask(onComplete: @escaping (Bool) -> Void) {
    stopRepeatTask()
    
    // The background task destruction is complete and a new background task can be started.
    if backgroundChannel == nil {
      onComplete(true)
    } else {
      backgroundChannel?.invokeMethod(ACTION_TASK_DESTROY, arguments: nil) { _ in
        for listener in self.taskLifecycleListeners {
          listener.onTaskDestroy()
        }
        onComplete(true)
      }
    }
  }
  
  private func startRepeatTask() {
    stopRepeatTask()
    
    if currBackgroundTaskOptions.isOnceEvent {
      backgroundChannel?.invokeMethod(ACTION_TASK_REPEAT_EVENT, arguments: nil) { _ in
        for listener in self.taskLifecycleListeners {
          listener.onTaskRepeatEvent()
        }
      }
    } else {
      let timeInterval = TimeInterval(currBackgroundTaskOptions.interval / 1000)
      repeatTask = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
        self.backgroundChannel?.invokeMethod(ACTION_TASK_REPEAT_EVENT, arguments: nil) { _ in
          for listener in self.taskLifecycleListeners {
            listener.onTaskRepeatEvent()
          }
        }
      }
    }
  }
  
  private func stopRepeatTask() {
    repeatTask?.invalidate()
    repeatTask = nil
  }
}
