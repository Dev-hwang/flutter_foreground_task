import Flutter
import UIKit
import BackgroundTasks

public class SwiftFlutterForegroundTaskPlugin: NSObject, FlutterPlugin {
  // ====================== Plugin ======================
  static private(set) var registerPlugins: FlutterPluginRegistrantCallback? = nil
  
  private var notificationPermissionManager: NotificationPermissionManager? = nil
  private var backgroundServiceManager: BackgroundServiceManager? = nil

  private var foregroundChannel: FlutterMethodChannel? = nil
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = SwiftFlutterForegroundTaskPlugin()
    instance.initServices()
    instance.initChannels(registrar.messenger())
    registrar.addApplicationDelegate(instance)
    if #available(iOS 13.0, *) {
      registrar.addSceneDelegate(instance)
    }
  }
  
  @objc public static func setPluginRegistrantCallback(_ callback: @escaping FlutterPluginRegistrantCallback) {
    registerPlugins = callback
  }

  @objc public static func registerAppRefreshForBackgroundLaunch() {
    if #available(iOS 13.0, *) {
      registerAppRefresh()
    }
  }
  
  public static func addTaskLifecycleListener(_ listener: FlutterForegroundTaskLifecycleListener) {
    BackgroundService.sharedInstance.addTaskLifecycleListener(listener)
  }
  
  public static func removeTaskLifecycleListener(_ listener: FlutterForegroundTaskLifecycleListener) {
    BackgroundService.sharedInstance.removeTaskLifecycleListener(listener)
  }
  
  private func initServices() {
    notificationPermissionManager = NotificationPermissionManager()
    backgroundServiceManager = BackgroundServiceManager()
  }
  
  private func initChannels(_ messenger: FlutterBinaryMessenger) {
    foregroundChannel = FlutterMethodChannel(name: "flutter_foreground_task/methods", binaryMessenger: messenger)
    foregroundChannel?.setMethodCallHandler(onMethodCall)
  }
  
  private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments
    do {
      switch call.method {
        case "checkNotificationPermission":
          notificationPermissionManager!.checkPermission { permission in
            result(permission.rawValue)
          }
        case "requestNotificationPermission":
          notificationPermissionManager!.requestPermission { permission in
            result(permission.rawValue)
          }
        case "setIosBackgroundRefreshEnabled":
          guard let enabled = args as? Bool else {
            result(FlutterError(code: "invalid-arguments", message: "Expected a boolean", details: nil))
            return
          }
          guard Self.refreshPolicy.setEnabled(enabled) else {
            result(FlutterError(code: "background-refresh-configuration", message: "Add the permitted identifier and register before app launch finishes", details: nil))
            return
          }
          result(nil)
        case "startService":
          try backgroundServiceManager!.start(arguments: args)
          result(true)
        case "restartService":
          try backgroundServiceManager!.restart(arguments: args)
          result(true)
        case "updateService":
          try backgroundServiceManager!.update(arguments: args)
          result(true)
        case "stopService":
          try backgroundServiceManager!.stop()
          result(true)
        case "sendData":
          backgroundServiceManager!.sendData(data: args)
        case "isRunningService":
          result(backgroundServiceManager!.isRunningService())
        case "minimizeApp":
          UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
        case "isAppOnForeground":
          result(UIApplication.shared.applicationState == .active)
        default:
          result(FlutterMethodNotImplemented)
      }
    } catch {
      let code = String(describing: error.self)
      let message = error.localizedDescription
      let flutterError = FlutterError(code: code, message: message, details: nil)
      result(flutterError)
    }
  }
  
  // ================== App Lifecycle ===================
  public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
    if Self.refreshEnabled {
      UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    }
    if #available(iOS 13.0, *) {
      SwiftFlutterForegroundTaskPlugin.registerAppRefresh()
    }
    return true
  }
  
  public func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
    completionHandler(.newData)
    return true
  }
  
  public func applicationDidEnterBackground(_ application: UIApplication) {
    if #available(iOS 13.0, *) {
      SwiftFlutterForegroundTaskPlugin.scheduleAppRefresh()
    }
  }
  
  public func applicationWillTerminate(_ application: UIApplication) {
    if !BackgroundService.sharedInstance.isRunningService {
      return
    }
    
    BackgroundServiceStatus.setData(action: BackgroundServiceAction.APP_TERMINATE)
    var isDestroyed = false
    BackgroundService.sharedInstance.run(onDestroyed: { isDestroyed = true })
    
    // Wait for onDestroy (max 2s); spin run loop so its reply is served. System allows ~5s total.
    let deadline = Date().addingTimeInterval(2)
    while !isDestroyed && Date() < deadline {
      RunLoop.current.run(mode: .default, before: deadline)
    }
  }

  // ================= Service Delegate =================
  @available(iOS 10.0, *)
  public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     didReceive response: UNNotificationResponse,
                                     withCompletionHandler completionHandler: @escaping () -> Void) {
    BackgroundService.sharedInstance.userNotificationCenter(center, response, completionHandler)
  }
  
  @available(iOS 10.0, *)
  public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     willPresent notification: UNNotification,
                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    BackgroundService.sharedInstance.userNotificationCenter(center, notification, completionHandler)
  }
  
  // ============== Background App Refresh ==============
  public static var refreshIdentifier: String = "com.pravera.flutter_foreground_task.refresh"
  private static var isBgTaskRegistered: Bool = false
  private static let refreshPolicy = IOSBackgroundRefreshPolicy(
    permitted: { refreshPermitted }, registered: { isBgTaskRegistered },
    cancel: { cancelAppRefresh() },
    cancelRunning: {
      for operation in refreshOperations.values { operation.cancel() }
    })
  private static var refreshLock: NSRecursiveLock { refreshPolicy.lock }
  private static var refreshOperations = [UUID: AppRefreshOperation]()
  private static var refreshPermitted: Bool {
    let permitted = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String] ?? []
    return permitted.contains(refreshIdentifier)
  }
  private static var refreshEnabled: Bool {
    refreshPolicy.enabled
  }

  @available(iOS 13.0, *)
  private static func registerAppRefresh() {
    refreshLock.lock()
    defer { refreshLock.unlock() }
    guard refreshPermitted else {
      cancelAppRefresh()
      return
    }
    if !refreshEnabled { cancelAppRefresh() }
    guard !isBgTaskRegistered else { return }
    isBgTaskRegistered = BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshIdentifier, using: nil) { task in
      handleAppRefresh(task: task as! BGAppRefreshTask)
    }
  }
  
  @available(iOS 13.0, *)
  private static func scheduleAppRefresh() {
    refreshPolicy.submitIfEnabled {
      let request = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
      request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
      do { try BGTaskScheduler.shared.submit(request) }
      catch { print("Could not schedule app refresh: \(error)") }
    }
  }
  
  @available(iOS 13.0, *)
  private static func cancelAppRefresh() {
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshIdentifier)
  }
  
  @available(iOS 13.0, *)
  private static func handleAppRefresh(task: BGAppRefreshTask) {
    refreshLock.lock()
    defer { refreshLock.unlock() }
    guard refreshEnabled else {
      task.setTaskCompleted(success: true)
      return
    }
    let queue = OperationQueue()
    let operation = AppRefreshOperation()
    let id = UUID()
    refreshOperations[id] = operation
    
    task.expirationHandler = {
      operation.cancel()
    }
    
    operation.completionBlock = { [weak operation] in
      refreshLock.lock()
      defer { refreshLock.unlock() }
      let cancelled = operation?.isCancelled ?? true
      refreshOperations.removeValue(forKey: id)
      if !cancelled { scheduleAppRefresh() }
      task.setTaskCompleted(success: !cancelled)
    }
    
    queue.addOperation(operation)
  }
}

class AppRefreshOperation: Operation, @unchecked Sendable {
  private let semaphore = DispatchSemaphore(value: 0)
  override func cancel() {
    super.cancel()
    semaphore.signal()
  }
  override func main() {
    if isCancelled { return }
    
    // avoid non-platform thread
    DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
      self.semaphore.signal()
    }
    
    semaphore.wait()
  }
}

@available(iOS 13.0, *)
extension SwiftFlutterForegroundTaskPlugin: FlutterSceneLifeCycleDelegate {
  public func sceneDidEnterBackground(_ scene: UIScene) {
    SwiftFlutterForegroundTaskPlugin.scheduleAppRefresh()
  }
}
