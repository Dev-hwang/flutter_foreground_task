import Flutter
import UIKit

public class SwiftFlutterForegroundTaskPlugin: NSObject, FlutterPlugin {
  static private(set) var registerPlugins: FlutterPluginRegistrantCallback? = nil
  
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
  
  @available(iOS 10.0, *)
  public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     didReceive response: UNNotificationResponse,
                                     withCompletionHandler completionHandler: @escaping () -> Void) {
    backgroundServiceManager?.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
  
  @available(iOS 10.0, *)
  public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                     willPresent notification: UNNotification,
                                     withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    backgroundServiceManager?.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
  }
  
  public func applicationWillTerminate(_ application: UIApplication) {
    do {
      try backgroundServiceManager!.stop()
      sleep(2) // Chance to handle onDestroy before app terminates
    } catch {
      // ServiceError.ServiceNotStartedException
    }
  }
}
