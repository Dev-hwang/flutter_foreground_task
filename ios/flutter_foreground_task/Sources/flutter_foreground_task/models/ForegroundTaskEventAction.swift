//
//  ForegroundTaskEventAction.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 8/28/24.
//

import Foundation

private let TASK_EVENT_TYPE_KEY = "taskEventType"
private let TASK_EVENT_INTERVAL_KEY = "taskEventInterval"

struct ForegroundTaskEventAction: Equatable {
  let type: ForegroundTaskEventType
  let interval: Int
  
  static func fromJsonString(_ jsonString: String) -> ForegroundTaskEventAction {
    var type: ForegroundTaskEventType = .NOTHING
    var interval: Int = 5000
    
    if let jsonData = jsonString.data(using: .utf8) {
      if let jsonObj = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? Dictionary<String, Any> {
        if let _type = jsonObj[TASK_EVENT_TYPE_KEY] as? Int {
          type = ForegroundTaskEventType.fromValue(_type)
        }
        
        if let _interval = jsonObj[TASK_EVENT_INTERVAL_KEY] as? Int {
          interval = _interval
        }
      }
    }
    
    return ForegroundTaskEventAction(type: type, interval: interval)
  }
  
  static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.type.rawValue == rhs.type.rawValue && lhs.interval == rhs.interval
  }
}
