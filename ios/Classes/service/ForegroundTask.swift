//
//  ForegroundTask.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 9/24/24.
//

import Foundation

private let BG_ISOLATE_NAME = "flutter_foreground_task/backgroundIsolate"
private let BG_CHANNEL_NAME = "flutter_foreground_task/background"

private let ACTION_TASK_START = "onStart"
private let ACTION_TASK_REPEAT_EVENT = "onRepeatEvent"
private let ACTION_TASK_DESTROY = "onDestroy"

class ForegroundTask {
  private let serviceStatus: BackgroundServiceStatus
  private let taskData: ForegroundTaskData
  private var taskEventAction: ForegroundTaskEventAction
  private let taskLifecycleListener: FlutterForegroundTaskLifecycleListener
  
  private var flutterEngine: FlutterEngine? = nil
  private var backgroundChannel: FlutterMethodChannel? = nil
  private var repeatTask: Timer? = nil
  private var isDestroyed: Bool = false
  
  init(
    serviceStatus: BackgroundServiceStatus,
    taskData: ForegroundTaskData,
    taskEventAction: ForegroundTaskEventAction,
    taskLifecycleListener: FlutterForegroundTaskLifecycleListener
  ) {
    self.serviceStatus = serviceStatus
    self.taskData = taskData
    self.taskEventAction = taskEventAction
    self.taskLifecycleListener = taskLifecycleListener
    initialize()
  }
  
  private func initialize() {
    guard let registerPlugins = SwiftFlutterForegroundTaskPlugin.registerPlugins else {
      print("Please register the registerPlugins function using the SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback.")
      return
    }
    
    guard let callbackHandle = taskData.callbackHandle else {
      // no callback -> Unlike Android, the flutter engine does not start.
      return
    }
    
    // lookup callback
    let callbackInfo = FlutterCallbackCache.lookupCallbackInformation(callbackHandle)
    guard let entrypoint = callbackInfo?.callbackName else {
      print("Entrypoint not found in callback information.")
      return
    }
    guard let libraryURI = callbackInfo?.callbackLibraryPath else {
      print("LibraryURI not found in callback information.")
      return
    }
    
    // create flutter engine & execute callback
    let flutterEngine = FlutterEngine(name: BG_ISOLATE_NAME, project: nil, allowHeadlessExecution: true)
    let isRunningEngine = flutterEngine.run(withEntrypoint: entrypoint, libraryURI: libraryURI)
    
    if isRunningEngine {
      // register plugins
      registerPlugins(flutterEngine)
      taskLifecycleListener.onEngineCreate(flutterEngine: flutterEngine)
      
      // create background channel
      let messenger = flutterEngine.binaryMessenger
      let backgroundChannel = FlutterMethodChannel(name: BG_CHANNEL_NAME, binaryMessenger: messenger)
      backgroundChannel.setMethodCallHandler(onMethodCall)
      
      self.flutterEngine = flutterEngine
      self.backgroundChannel = backgroundChannel
    }
  }
  
  func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "start":
        start()
      default:
        result(FlutterMethodNotImplemented)
    }
  }
  
  private func start() {
    runIfNotDestroyed {
      runIfCallbackHandleExists {
        let serviceAction = serviceStatus.action
        let starter: FlutterForegroundTaskStarter
        if serviceAction == .API_START || serviceAction == .API_RESTART || serviceAction == .API_UPDATE {
          starter = .DEVELOPER
        } else {
          starter = .SYSTEM
        }
        
        backgroundChannel?.invokeMethod(ACTION_TASK_START, arguments: starter.rawValue) { _ in
          self.runIfNotDestroyed {
            self.startRepeatTask()
          }
        }
        taskLifecycleListener.onTaskStart(starter: starter)
      }
    }
  }
  
  private func invokeTaskRepeatEvent() {
    backgroundChannel?.invokeMethod(ACTION_TASK_REPEAT_EVENT, arguments: nil)
    taskLifecycleListener.onTaskRepeatEvent()
  }
  
  private func startRepeatTask() {
    stopRepeatTask()
    
    let type = taskEventAction.type
    let interval = TimeInterval(Double(taskEventAction.interval) / 1000)
    
    if type == .NOTHING {
      return
    }
    
    if type == .ONCE {
      invokeTaskRepeatEvent()
      return
    }
    
    repeatTask = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
      self.invokeTaskRepeatEvent()
    }
  }
  
  private func stopRepeatTask() {
    repeatTask?.invalidate()
    repeatTask = nil
  }
  
  func invokeMethod(_ method: String, arguments: Any?) {
    runIfNotDestroyed {
      backgroundChannel?.invokeMethod(method, arguments: arguments)
    }
  }
  
  func update(taskEventAction: ForegroundTaskEventAction) {
    runIfNotDestroyed {
      runIfCallbackHandleExists {
        self.taskEventAction = taskEventAction
        startRepeatTask()
      }
    }
  }
  
  func destroy() {
    runIfNotDestroyed {
      stopRepeatTask()
      
      backgroundChannel?.setMethodCallHandler(nil)
      if taskData.callbackHandle == nil {
        taskLifecycleListener.onEngineWillDestroy()
        flutterEngine?.destroyContext()
        flutterEngine = nil
      } else {
        backgroundChannel?.invokeMethod(ACTION_TASK_DESTROY, arguments: nil) { _ in
          self.flutterEngine?.destroyContext()
          self.flutterEngine = nil
        }
        taskLifecycleListener.onTaskDestroy()
        taskLifecycleListener.onEngineWillDestroy()
      }
      
      isDestroyed = true
    }
  }
  
  private func runIfCallbackHandleExists(call: () -> Void) {
    if taskData.callbackHandle == nil {
      return
    }
    call()
  }

  private func runIfNotDestroyed(call: () -> Void) {
    if isDestroyed {
      return
    }
    call()
  }
}
