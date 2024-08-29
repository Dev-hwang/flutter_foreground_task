//
//  BackgroundTaskData.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 8/2/24.
//

import Foundation

struct BackgroundTaskData {
  let callbackHandle: Int64?
  
  static func getData() -> BackgroundTaskData {
    let prefs = UserDefaults.standard
    
    let callbackHandle = prefs.object(forKey: CALLBACK_HANDLE) as? Int64
    
    return BackgroundTaskData(callbackHandle: callbackHandle)
  }
  
  static func setData(args: Dictionary<String, Any>) {
    let prefs = UserDefaults.standard
    
    prefs.removeObject(forKey: CALLBACK_HANDLE)
    if let callbackHandle = args[CALLBACK_HANDLE] as? Int64 {
      prefs.set(callbackHandle, forKey: CALLBACK_HANDLE)
    }
  }
  
  static func updateData(args: Dictionary<String, Any>) {
    let prefs = UserDefaults.standard
    
    if let callbackHandle = args[CALLBACK_HANDLE] as? Int64 {
      prefs.set(callbackHandle, forKey: CALLBACK_HANDLE)
    }
  }
  
  static func clearData() {
    let prefs = UserDefaults.standard
    prefs.removeObject(forKey: CALLBACK_HANDLE)
  }
}
