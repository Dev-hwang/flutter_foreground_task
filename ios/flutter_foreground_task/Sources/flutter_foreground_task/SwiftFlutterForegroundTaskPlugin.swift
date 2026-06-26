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
  }
  
  public static func setPluginRegistrantCallback(_ callback: @escaping FlutterPluginRegistrantCallback) {
    registerPlugins = callback
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
    UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
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
    BackgroundService.sharedInstance.run()
    
    // Chance to handle onDestroy before app terminates
    sleep(5)
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

  @available(iOS 13.0, *)
  private static func registerAppRefresh() {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshIdentifier, using: nil) { task in
      handleAppRefresh(task: task as! BGAppRefreshTask)
    }
  }
  
  @available(iOS 13.0, *)
  private static func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    
    do {
      try BGTaskScheduler.shared.submit(request)
    } catch {
      print("Could not schedule app refresh: \(error)")
    }
  }
  
  @available(iOS 13.0, *)
  private static func cancelAppRefresh() {
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshIdentifier)
  }
  
  @available(iOS 13.0, *)
  private static func handleAppRefresh(task: BGAppRefreshTask) {
    let queue = OperationQueue()
    let operation = AppRefreshOperation()
    
    task.expirationHandler = {
      operation.cancel()
    }
    
    operation.completionBlock = {
      // Schedule a new refresh task
      scheduleAppRefresh()

      task.setTaskCompleted(success: true)
    }
    
    queue.addOperation(operation)
  }
}

class AppRefreshOperation: Operation {
  override func main() {
    let semaphore = DispatchSemaphore(value: 0)
    
    // avoid non-platform thread
    DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
      semaphore.signal()
    }
    
    semaphore.wait()
  }
}
