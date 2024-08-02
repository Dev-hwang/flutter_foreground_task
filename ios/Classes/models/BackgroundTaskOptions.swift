//
//  BackgroundTaskOptions.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 8/2/24.
//

import Foundation

struct BackgroundTaskOptions {
  let interval: Int
  let isOnceEvent: Bool
  
  static func getData() -> BackgroundTaskOptions {
    let prefs = UserDefaults.standard
    let interval = prefs.integer(forKey: TASK_INTERVAL)
    let isOnceEvent = prefs.bool(forKey: IS_ONCE_EVENT)
    
    return BackgroundTaskOptions(interval: interval, isOnceEvent: isOnceEvent)
  }
  
  static func setData(args: Dictionary<String, Any>) {
    let interval = args[TASK_INTERVAL] as? Int ?? 5000
    let isOnceEvent = args[IS_ONCE_EVENT] as? Bool ?? false
    
    let prefs = UserDefaults.standard
    prefs.set(interval, forKey: TASK_INTERVAL)
    prefs.set(isOnceEvent, forKey: IS_ONCE_EVENT)
  }
  
  static func updateData(args: Dictionary<String, Any>) {
    let prefs = UserDefaults.standard
    if let interval = args[TASK_INTERVAL] as? Int {
      prefs.set(interval, forKey: TASK_INTERVAL)
    }
    if let isOnceEvent = args[IS_ONCE_EVENT] as? Bool {
      prefs.set(isOnceEvent, forKey: IS_ONCE_EVENT)
    }
  }
  
  static func clearData() {
    let prefs = UserDefaults.standard
    prefs.removeObject(forKey: TASK_INTERVAL)
    prefs.removeObject(forKey: IS_ONCE_EVENT)
  }
}
