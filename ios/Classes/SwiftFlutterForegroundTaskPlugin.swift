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
    foregroundChannel = FlutterMethodChannel(name: "flutter_foreground_task/method", binaryMessenger: messenger)
    foregroundChannel?.setMethodCallHandler(onMethodCall)
  }
  
  private func onMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case "startForegroundService":
        backgroundServiceManager?.start(call: call)
      case "updateForegroundService":
        backgroundServiceManager?.update(call: call)
      case "stopForegroundService":
        backgroundServiceManager?.stop()
      case "isRunningService":
        result(backgroundServiceManager?.isRunningService() ?? false)
      default:
        result(FlutterMethodNotImplemented)
    }
  }
}
