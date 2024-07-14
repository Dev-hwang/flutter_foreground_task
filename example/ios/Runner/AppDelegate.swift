import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback(registerPlugins)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    
    var taskLifecycleListener = FlutterForegroundTaskLifecycleListenerImpl()
    SwiftFlutterForegroundTaskPlugin.setTaskLifecycleListener(taskLifecycleListener)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

func registerPlugins(registry: FlutterPluginRegistry) {
  GeneratedPluginRegistrant.register(with: registry)
}

class FlutterForegroundTaskLifecycleListenerImpl: FlutterForegroundTaskLifecycleListener {
  func onCreateFlutterEngine(flutterEngine: FlutterEngine?) {
    print("Native-onCreateFlutterEngine")
  }
  
  func onTaskStart() {
    print("Native-onTaskStart")
  }
  
  func onTaskRepeatEvent() {
    print("Native-onTaskRepeatEvent")
  }
  
  func onTaskDestroy() {
    print("Native-onTaskDestroy")
  }
  
  func onDestroyFlutterEngine() {
    print("Native-onDestroyFlutterEngine")
  }
}
