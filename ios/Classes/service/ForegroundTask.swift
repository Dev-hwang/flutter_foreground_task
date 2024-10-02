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
    
    if let registerPlugins = SwiftFlutterForegroundTaskPlugin.registerPlugins {
      // create flutter engine
      let flutterEngine = FlutterEngine(name: BG_ISOLATE_NAME, project: nil, allowHeadlessExecution: true)
      
      // lookup callback
      var entrypoint: String? = nil
      var libraryURI: String? = nil
      if let callbackHandle = taskData.callbackHandle {
        let callbackInfo = FlutterCallbackCache.lookupCallbackInformation(callbackHandle)
        entrypoint = callbackInfo?.callbackName
        libraryURI = callbackInfo?.callbackLibraryPath
      }
      
      // run flutter engine & execute callback
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
    } else {
      print("Please register the registerPlugins function using the SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback.")
    }
  }
  
  func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "start":
        callSafely { start() }
      default:
        result(FlutterMethodNotImplemented)
    }
  }
  
  private func start() {
    let serviceAction = serviceStatus.action
    let starter: FlutterForegroundTaskStarter
    if serviceAction == .API_START || serviceAction == .API_RESTART || serviceAction == .API_UPDATE {
      starter = .DEVELOPER
    } else {
      starter = .SYSTEM
    }
    
    backgroundChannel?.invokeMethod(ACTION_TASK_START, arguments: starter.rawValue) { _ in
      self.callSafely { self.startRepeatTask() }
    }
    
    taskLifecycleListener.onTaskStart(starter: starter)
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
    callSafely(onlyCheckDestroyed: true) {
      backgroundChannel?.invokeMethod(method, arguments: arguments)
    }
  }
  
  func update(taskEventAction: ForegroundTaskEventAction) {
    callSafely {
      self.taskEventAction = taskEventAction
      startRepeatTask()
    }
  }
  
  func destroy() {
    callSafely(onlyCheckDestroyed: true) {
      stopRepeatTask()
      
      backgroundChannel?.setMethodCallHandler(nil)
      backgroundChannel?.invokeMethod(ACTION_TASK_DESTROY, arguments: nil) { _ in
        self.flutterEngine?.destroyContext()
        self.flutterEngine = nil
      }
      
      taskLifecycleListener.onTaskDestroy()
      taskLifecycleListener.onEngineWillDestroy()
      isDestroyed = true
    }
  }
  
  private func callSafely(onlyCheckDestroyed: Bool = false, call: () -> Void = {}) {
    if isDestroyed || (!onlyCheckDestroyed && taskData.callbackHandle == nil) {
      return
    }
    call()
  }
}
