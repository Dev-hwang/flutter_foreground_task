//
//  BackgroundService.swift
//  flutter_foreground_task
//
//  Created by WOO JIN HWANG on 2021/08/11.
//

import Flutter
import Foundation
import UserNotifications

private let NOTIFICATION_ID: String = "flutter_foreground_task/notification"
private let NOTIFICATION_CATEGORY_ID: String = "flutter_foreground_task/notification_category"
private let BG_ISOLATE_NAME: String = "flutter_foreground_task/backgroundIsolate"
private let BG_CHANNEL_NAME: String = "flutter_foreground_task/background"

private let ACTION_TASK_START: String = "onStart"
private let ACTION_TASK_REPEAT_EVENT: String = "onRepeatEvent"
private let ACTION_TASK_DESTROY: String = "onDestroy"
private let ACTION_RECEIVE_DATA: String = "onReceiveData"

private let ACTION_NOTIFICATION_BUTTON_PRESSED = "onNotificationButtonPressed"
private let ACTION_NOTIFICATION_PRESSED = "onNotificationPressed"
private let ACTION_NOTIFICATION_DISMISSED = "onNotificationDismissed"

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
  private let notificationPermissionManager: NotificationPermissionManager
  private var canReceiveNotificationResponse: Bool = false

  private var backgroundServiceStatus: BackgroundServiceStatus
  private var notificationOptions: NotificationOptions
  private var notificationContent: NotificationContent
  private var prevBackgroundTaskOptions: BackgroundTaskOptions?
  private var currBackgroundTaskOptions: BackgroundTaskOptions
  private var prevBackgroundTaskData: BackgroundTaskData?
  private var currBackgroundTaskData: BackgroundTaskData
  
  override init() {
    notificationCenter = UNUserNotificationCenter.current()
    notificationPermissionManager = NotificationPermissionManager()
    backgroundServiceStatus = BackgroundServiceStatus.getData()
    notificationOptions = NotificationOptions.getData()
    notificationContent = NotificationContent.getData()
    currBackgroundTaskOptions = BackgroundTaskOptions.getData()
    currBackgroundTaskData = BackgroundTaskData.getData()
    super.init()
  }
  
  func run() {
    backgroundServiceStatus = BackgroundServiceStatus.getData()
    notificationOptions = NotificationOptions.getData()
    notificationContent = NotificationContent.getData()
    prevBackgroundTaskOptions = currBackgroundTaskOptions
    currBackgroundTaskOptions = BackgroundTaskOptions.getData()
    prevBackgroundTaskData = currBackgroundTaskData
    currBackgroundTaskData = BackgroundTaskData.getData()

    switch backgroundServiceStatus.action {
      case .API_START, .API_RESTART:
        requestNotification()
        isRunningService = true
        if let callbackHandle = currBackgroundTaskData.callbackHandle {
          executeDartCallback(callbackHandle: callbackHandle)
        }
        break
      case .API_UPDATE:
        requestNotification()
        isRunningService = true
        if let callbackHandle = currBackgroundTaskData.callbackHandle {
          if prevBackgroundTaskData?.callbackHandle != callbackHandle {
            executeDartCallback(callbackHandle: callbackHandle)
          } else {
            let prevEventAction = prevBackgroundTaskOptions?.eventAction
            let currEventAction = currBackgroundTaskOptions.eventAction
            if prevEventAction != currEventAction {
              startRepeatTask()
            }
          }
        }
        break
      case .API_STOP, .APP_TERMINATE:
        destroyBackgroundTask {
          self.disposeBackgroundChannel()
          self.destroyFlutterEngine()
        }
        removeAllNotification()
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
    } else if actionId == UNNotificationDefaultActionIdentifier {
      backgroundChannel?.invokeMethod(ACTION_NOTIFICATION_PRESSED, arguments: nil)
    } else if actionId == UNNotificationDismissActionIdentifier {
      backgroundChannel?.invokeMethod(ACTION_NOTIFICATION_DISMISSED, arguments: nil)
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
  
  private func setNotificationActions() {
    var actions: [UNNotificationAction] = []
    for button in notificationContent.buttons {
      let action = UNNotificationAction(identifier: button.id, title: button.text)
      actions.append(action)
    }
    
    let category = UNNotificationCategory(
      identifier: NOTIFICATION_CATEGORY_ID,
      actions: actions,
      intentIdentifiers: [],
      options: .customDismissAction
    )
    
    notificationCenter.setNotificationCategories([category])
  }
  
  private func requestNotification() {
    if !notificationOptions.showNotification {
      return
    }
    
    notificationPermissionManager.checkPermission { permission in
      if permission == NotificationPermission.DENIED {
        return
      }
      
      let content = UNMutableNotificationContent()
      content.title = self.notificationContent.title
      content.body = self.notificationContent.text
      content.categoryIdentifier = NOTIFICATION_CATEGORY_ID
      if self.notificationOptions.playSound {
        content.sound = .default
      }
      self.setNotificationActions()
      
      let request = UNNotificationRequest(identifier: NOTIFICATION_ID, content: content, trigger: nil)
      self.notificationCenter.add(request, withCompletionHandler: nil)
    }
  }
  
  private func removeAllNotification() {
    notificationCenter.removePendingNotificationRequests(withIdentifiers: [NOTIFICATION_ID])
    notificationCenter.removeDeliveredNotifications(withIdentifiers: [NOTIFICATION_ID])
  }
  
  private func executeDartCallback(callbackHandle: Int64) {
    destroyBackgroundTask {
      if SwiftFlutterForegroundTaskPlugin.registerPlugins == nil {
        print("Please register the registerPlugins function using the SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback.")
        return
      }
      
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
  
  private func startBackgroundTask(onComplete: @escaping () -> Void = {}) {
    stopRepeatTask()
    
    if backgroundChannel == nil {
      onComplete()
      return
    }
    
    let serviceAction = backgroundServiceStatus.action
    let starter: FlutterForegroundTaskStarter
    switch serviceAction {
      case .API_START, .API_RESTART, .API_UPDATE:
        starter = .DEVELOPER
        break
      default:
        starter = .SYSTEM
        break
    }
    
    backgroundChannel?.invokeMethod(ACTION_TASK_START, arguments: starter.rawValue) { _ in
      self.startRepeatTask()
      onComplete()
    }
    
    for listener in self.taskLifecycleListeners {
      listener.onTaskStart(starter: starter)
    }
  }
  
  private func destroyBackgroundTask(onComplete: @escaping () -> Void = {}) {
    stopRepeatTask()

    if backgroundChannel == nil {
      onComplete()
      return
    }
    
    backgroundChannel?.invokeMethod(ACTION_TASK_DESTROY, arguments: nil) { _ in
      onComplete()
    }
    
    for listener in self.taskLifecycleListeners {
      listener.onTaskDestroy()
    }
  }
  
  private func invokeTaskRepeatEvent() {
    backgroundChannel?.invokeMethod(ACTION_TASK_REPEAT_EVENT, arguments: nil)
    
    for listener in self.taskLifecycleListeners {
      listener.onTaskRepeatEvent()
    }
  }
  
  private func startRepeatTask() {
    stopRepeatTask()
    
    let type = currBackgroundTaskOptions.eventAction.type
    let interval = currBackgroundTaskOptions.eventAction.interval
    
    if type == .NOTHING {
      return
    }
    
    if type == .ONCE {
      invokeTaskRepeatEvent()
      return
    }
    
    let timeInterval = TimeInterval(Double(interval) / 1000)
    repeatTask = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { _ in
      self.invokeTaskRepeatEvent()
    }
  }
  
  private func stopRepeatTask() {
    repeatTask?.invalidate()
    repeatTask = nil
  }
}
