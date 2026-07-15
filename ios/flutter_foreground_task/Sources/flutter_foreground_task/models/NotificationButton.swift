//
//  NotificationButton.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 8/5/24.
//

import Foundation

private let ID_KEY = "id"
private let TEXT_KEY = "text"

struct NotificationButton {
  let id: String
  let text: String
  
  static func fromJSONObject(_ jsonObj: Any) -> NotificationButton {
    var id: String = "unknown"
    var text: String = ""
    
    if let _jsonObj = jsonObj as? Dictionary<String, Any> {
      if let _id = _jsonObj[ID_KEY] as? String {
        id = _id
      }
      
      if let _text = _jsonObj[TEXT_KEY] as? String {
        text = _text
      }
    }
    
    return NotificationButton(id: id, text: text)
  }
}
