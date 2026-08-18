#if SWIFT_PACKAGE

import Flutter

@objc(FlutterForegroundTaskPlugin)
public class FlutterForegroundTaskPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    SwiftFlutterForegroundTaskPlugin.register(with: registrar)
  }

  public static func setPluginRegistrantCallback(
    _ callback: @escaping FlutterPluginRegistrantCallback
  ) {
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback(callback)
  }
}

@_cdecl("flutter_foreground_task_register_app_refresh")
public func flutter_foreground_task_register_app_refresh() {
  SwiftFlutterForegroundTaskPlugin.registerAppRefreshForBackgroundLaunch()
}

#endif