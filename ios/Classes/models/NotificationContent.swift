//
//  NotificationContent.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 8/2/24.
//

import Foundation

struct NotificationContent {
  let title: String
  let text: String
  
  static func getData() -> NotificationContent {
    let prefs = UserDefaults.standard
    let title = prefs.string(forKey: NOTIFICATION_CONTENT_TITLE) ?? ""
    let text = prefs.string(forKey: NOTIFICATION_CONTENT_TEXT) ?? ""
    
    return NotificationContent(title: title, text: text)
  }
  
  static func setData(args: Dictionary<String, Any>) {
    let title = args[NOTIFICATION_CONTENT_TITLE] as? String ?? ""
    let text = args[NOTIFICATION_CONTENT_TEXT] as? String ?? ""
    
    let prefs = UserDefaults.standard
    prefs.set(title, forKey: NOTIFICATION_CONTENT_TITLE)
    prefs.set(text, forKey: NOTIFICATION_CONTENT_TEXT)
  }
  
  static func updateData(args: Dictionary<String, Any>) {
    let prefs = UserDefaults.standard
    if let title = args[NOTIFICATION_CONTENT_TITLE] as? String {
      prefs.set(title, forKey: NOTIFICATION_CONTENT_TITLE)
    }
    if let text = args[NOTIFICATION_CONTENT_TEXT] as? String {
      prefs.set(text, forKey: NOTIFICATION_CONTENT_TEXT)
    }
  }
  
  static func clearData() {
    let prefs = UserDefaults.standard
    prefs.removeObject(forKey: NOTIFICATION_CONTENT_TITLE)
    prefs.removeObject(forKey: NOTIFICATION_CONTENT_TEXT)
  }
}
