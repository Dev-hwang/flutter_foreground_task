//
//  ForegroundTaskEventType.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 8/28/24.
//

import Foundation

enum ForegroundTaskEventType: Int {
  case NOTHING = 1
  case ONCE = 2
  case REPEAT = 3
  
  static func fromValue(_ value: Int) -> ForegroundTaskEventType {
    return ForegroundTaskEventType(rawValue: value) ?? .NOTHING
  }
}
