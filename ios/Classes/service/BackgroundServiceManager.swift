//
//  BackgroundServiceManager.swift
//  flutter_foreground_task
//
//  Created by WOO JIN HWANG on 2021/08/10.
//

import Flutter
import Foundation

class BackgroundServiceManager: NSObject {
  func start(call: FlutterMethodCall) -> Bool {
    if #available(iOS 10.0, *) {
      saveOptions(call: call)
      BackgroundService.sharedInstance.run(action: BackgroundServiceAction.START)
    } else {
      // Fallback on earlier versions
      return false
    }
    
    return true
  }
  
  func restart(call: FlutterMethodCall) -> Bool {
    if #available(iOS 10.0, *) {
      BackgroundService.sharedInstance.run(action: BackgroundServiceAction.RESTART)
    } else {
      // Fallback on earlier versions
      return false
    }
    
    return true
  }
  
  func update(call: FlutterMethodCall) -> Bool {
    if #available(iOS 10.0, *) {
      updateOptions(call: call)
      BackgroundService.sharedInstance.run(action: BackgroundServiceAction.UPDATE)
    } else {
      // Fallback on earlier versions
      return false
    }
    
    return true
  }
  
  func stop() -> Bool {
    if #available(iOS 10.0, *) {
      clearOptions()
      BackgroundService.sharedInstance.run(action: BackgroundServiceAction.STOP)
    } else {
      // Fallback on earlier versions
      return false
    }
    
    return true
  }
  
  func isRunningService() -> Bool {
    if #available(iOS 10.0, *) {
      return BackgroundService.sharedInstance.isRunningService
    } else {
      return false
    }
  }
  
  private func saveOptions(call: FlutterMethodCall) {
    guard let argsDict = call.arguments as? Dictionary<String, Any> else { return }
    let prefs = UserDefaults.standard
    
    let notificationContentTitle = argsDict[NOTIFICATION_CONTENT_TITLE] as? String ?? ""
    let notificationContentText = argsDict[NOTIFICATION_CONTENT_TEXT] as? String ?? ""
    let showNotification = argsDict[SHOW_NOTIFICATION] as? Bool ?? true
    let playSound = argsDict[PLAY_SOUND] as? Bool ?? false
    let taskInterval = argsDict[TASK_INTERVAL] as? Int ?? 5000
    let isOnceEvent = argsDict[IS_ONCE_EVENT] as? Bool ?? false
    let callbackHandle = argsDict[CALLBACK_HANDLE] as? Int64
    
    prefs.set(notificationContentTitle, forKey: NOTIFICATION_CONTENT_TITLE)
    prefs.set(notificationContentText, forKey: NOTIFICATION_CONTENT_TEXT)
    prefs.set(showNotification, forKey: SHOW_NOTIFICATION)
    prefs.set(playSound, forKey: PLAY_SOUND)
    prefs.set(taskInterval, forKey: TASK_INTERVAL)
    prefs.set(isOnceEvent, forKey: IS_ONCE_EVENT)
    prefs.removeObject(forKey: CALLBACK_HANDLE)
    if callbackHandle != nil {
      prefs.set(callbackHandle, forKey: CALLBACK_HANDLE)
    }
  }
  
  private func updateOptions(call: FlutterMethodCall) {
    guard let argsDict = call.arguments as? Dictionary<String, Any> else { return }
    let prefs = UserDefaults.standard
    
    let notificationContentTitle = argsDict[NOTIFICATION_CONTENT_TITLE] as? String
      ?? prefs.string(forKey: NOTIFICATION_CONTENT_TITLE)
      ?? ""
    let notificationContentText = argsDict[NOTIFICATION_CONTENT_TEXT] as? String
      ?? prefs.string(forKey: NOTIFICATION_CONTENT_TEXT)
      ?? ""
    let taskInterval = argsDict[TASK_INTERVAL] as? Int
    let isOnceEvent = argsDict[IS_ONCE_EVENT] as? Bool
    let callbackHandle = argsDict[CALLBACK_HANDLE] as? Int64
    
    prefs.set(notificationContentTitle, forKey: NOTIFICATION_CONTENT_TITLE)
    prefs.set(notificationContentText, forKey: NOTIFICATION_CONTENT_TEXT)
    if taskInterval != nil {
      prefs.set(taskInterval, forKey: TASK_INTERVAL)
    }
    if isOnceEvent != nil {
      prefs.set(isOnceEvent, forKey: IS_ONCE_EVENT)
    }
    if callbackHandle != nil {
      prefs.set(callbackHandle, forKey: CALLBACK_HANDLE)
    }
  }
  
  private func clearOptions() {
    let prefs = UserDefaults.standard
    prefs.removeObject(forKey: NOTIFICATION_CONTENT_TITLE)
    prefs.removeObject(forKey: NOTIFICATION_CONTENT_TEXT)
    prefs.removeObject(forKey: SHOW_NOTIFICATION)
    prefs.removeObject(forKey: PLAY_SOUND)
    prefs.removeObject(forKey: TASK_INTERVAL)
    prefs.removeObject(forKey: IS_ONCE_EVENT)
    prefs.removeObject(forKey: CALLBACK_HANDLE)
  }
  
  @available(iOS 10.0, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    BackgroundService.sharedInstance
      .userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }
  
  @available(iOS 10.0, *)
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    BackgroundService.sharedInstance
      .userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
  }
}
