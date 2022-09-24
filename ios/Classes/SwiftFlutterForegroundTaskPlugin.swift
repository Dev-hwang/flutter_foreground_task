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
  
  private func initServices() {
    backgroundServiceManager = BackgroundServiceManager()
  }
  
  private func initChannels(_ messenger: FlutterBinaryMessenger) {
    foregroundChannel = FlutterMethodChannel(name: "flutter_foreground_task/methods", binaryMessenger: messenger)
    foregroundChannel?.setMethodCallHandler(onMethodCall)
  }
  
  private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "startService":
        result(backgroundServiceManager?.start(call: call) ?? false)
      case "restartService":
        result(backgroundServiceManager?.restart(call: call) ?? false)
      case "updateService":
        result(backgroundServiceManager?.update(call: call) ?? false)
      case "stopService":
        result(backgroundServiceManager?.stop() ?? false)
      case "isRunningService":
        result(backgroundServiceManager?.isRunningService() ?? false)
      case "minimizeApp":
        UIControl().sendAction(#selector(URLSessionTask.suspend), to: UIApplication.shared, for: nil)
      case "isAppOnForeground":
        result(UIApplication.shared.applicationState == .active)
      default:
        result(FlutterMethodNotImplemented)
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
}
