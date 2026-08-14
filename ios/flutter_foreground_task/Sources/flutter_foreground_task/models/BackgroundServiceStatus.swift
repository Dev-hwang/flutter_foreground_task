//
//  BackgroundServiceStatus.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 9/13/24.
//

import Foundation

struct BackgroundServiceStatus {
  let action: BackgroundServiceAction
  
  static func getData() -> BackgroundServiceStatus {
    let prefs = UserDefaults.standard
    let actionValue = prefs.string(forKey: BACKGROUND_SERVICE_ACTION) ?? BackgroundServiceAction.API_STOP.rawValue
    let action = BackgroundServiceAction(rawValue: actionValue)!
    
    return BackgroundServiceStatus(action: action)
  }
  
  static func setData(action: BackgroundServiceAction) {
    let prefs = UserDefaults.standard
    prefs.set(action.rawValue, forKey: BACKGROUND_SERVICE_ACTION)
  }
}
