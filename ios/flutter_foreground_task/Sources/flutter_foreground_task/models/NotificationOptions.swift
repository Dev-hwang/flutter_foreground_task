//
//  NotificationOptions.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 8/2/24.
//

import Foundation

struct NotificationOptions {
  let showNotification: Bool
  let playSound: Bool
  
  static func getData() -> NotificationOptions {
    let prefs = UserDefaults.standard
    
    let showNotification = prefs.bool(forKey: SHOW_NOTIFICATION)
    let playSound = prefs.bool(forKey: PLAY_SOUND)
    
    return NotificationOptions(showNotification: showNotification, playSound: playSound)
  }
  
  static func setData(args: Dictionary<String, Any>) {
    let prefs = UserDefaults.standard
    
    let showNotification = args[SHOW_NOTIFICATION] as? Bool ?? false
    let playSound = args[PLAY_SOUND] as? Bool ?? false

    prefs.set(showNotification, forKey: SHOW_NOTIFICATION)
    prefs.set(playSound, forKey: PLAY_SOUND)
  }
  
  static func clearData() {
    let prefs = UserDefaults.standard
    prefs.removeObject(forKey: SHOW_NOTIFICATION)
    prefs.removeObject(forKey: PLAY_SOUND)
  }
}
