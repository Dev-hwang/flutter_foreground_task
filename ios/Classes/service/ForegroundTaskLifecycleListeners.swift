//
//  ForegroundTaskLifecycleListeners.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 9/24/24.
//

import Foundation

class ForegroundTaskLifecycleListeners : FlutterForegroundTaskLifecycleListener {
  private var listeners: Array<FlutterForegroundTaskLifecycleListener> = []
  
  func addListener(_ listener: FlutterForegroundTaskLifecycleListener) {
    if listeners.contains(where: { $0 === listener }) == false {
      listeners.append(listener)
    }
  }
  
  func removeListener(_ listener: FlutterForegroundTaskLifecycleListener) {
    if let index = listeners.firstIndex(where: { $0 === listener }) {
      listeners.remove(at: index)
    }
  }
  
  func onEngineCreate(flutterEngine: FlutterEngine?) {
    for listener in listeners {
      listener.onEngineCreate(flutterEngine: flutterEngine)
    }
  }
  
  func onTaskStart(starter: FlutterForegroundTaskStarter) {
    for listener in listeners {
      listener.onTaskStart(starter: starter)
    }
  }
  
  func onTaskRepeatEvent() {
    for listener in listeners {
      listener.onTaskRepeatEvent()
    }
  }
  
  func onTaskDestroy() {
    for listener in listeners {
      listener.onTaskDestroy()
    }
  }
  
  func onEngineWillDestroy() {
    for listener in listeners {
      listener.onEngineWillDestroy()
    }
  }
}
