//
//  ForegroundTaskOptions.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 9/24/24.
//

import Foundation

struct ForegroundTaskOptions {
  let eventAction: ForegroundTaskEventAction
  
  static func getData() -> ForegroundTaskOptions {
    let prefs = UserDefaults.standard
    
    let eventActionJsonString = prefs.string(forKey: TASK_EVENT_ACTION)
    let eventAction: ForegroundTaskEventAction
    if eventActionJsonString != nil {
      eventAction = ForegroundTaskEventAction.fromJsonString(eventActionJsonString!)
    } else {
      // for deprecated api
      let oldIsOnceEvent = prefs.bool(forKey: IS_ONCE_EVENT)
      let oldInterval = prefs.integer(forKey: INTERVAL)
      if oldIsOnceEvent {
        eventAction = ForegroundTaskEventAction(type: .ONCE, interval: oldInterval)
      } else {
        eventAction = ForegroundTaskEventAction(type: .REPEAT, interval: oldInterval)
      }
    }
    
    return ForegroundTaskOptions(eventAction: eventAction)
  }
  
  static func setData(args: Dictionary<String, Any>) {
    let prefs = UserDefaults.standard
    
    if let eventActionJson = args[TASK_EVENT_ACTION] as? Dictionary<String, Any> {
      if let eventActionJsonData = try? JSONSerialization.data(withJSONObject: eventActionJson, options: []) {
        if let eventActionJsonString = String(data: eventActionJsonData, encoding: .utf8) {
          prefs.set(eventActionJsonString, forKey: TASK_EVENT_ACTION)
        }
      }
    }
  }
  
  static func updateData(args: Dictionary<String, Any>) {
    let prefs = UserDefaults.standard
    
    if let eventActionJson = args[TASK_EVENT_ACTION] as? Dictionary<String, Any> {
      if let eventActionJsonData = try? JSONSerialization.data(withJSONObject: eventActionJson, options: []) {
        if let eventActionJsonString = String(data: eventActionJsonData, encoding: .utf8) {
          prefs.set(eventActionJsonString, forKey: TASK_EVENT_ACTION)
        }
      }
    }
  }
  
  static func clearData() {
    let prefs = UserDefaults.standard
    prefs.removeObject(forKey: TASK_EVENT_ACTION) // new
    prefs.removeObject(forKey: INTERVAL) // deprecated
    prefs.removeObject(forKey: IS_ONCE_EVENT) // deprecated
  }
}
