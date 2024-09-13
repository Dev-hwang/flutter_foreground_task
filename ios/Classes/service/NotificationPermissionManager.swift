//
//  NotificationPermissionManager.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 8/6/24.
//

import Foundation

class NotificationPermissionManager {
  func checkPermission(completion: @escaping (NotificationPermission) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      switch settings.authorizationStatus {
        case .authorized:
          completion(NotificationPermission.GRANTED)
        case .denied, .ephemeral, .notDetermined, .provisional:
          completion(NotificationPermission.DENIED)
        @unknown default:
          completion(NotificationPermission.DENIED)
      }
    }
  }
  
  func requestPermission(completion: @escaping (NotificationPermission) -> Void) {
    let options = UNAuthorizationOptions(arrayLiteral: .alert, .sound)
    UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
      if error != nil {
        completion(NotificationPermission.DENIED)
      } else {
        if (granted) {
          completion(NotificationPermission.GRANTED)
        } else {
          completion(NotificationPermission.DENIED)
        }
      }
    }
  }
}
