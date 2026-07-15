//
//  FlutterForegroundTaskLifecycleListener.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 7/15/24.
//

import Foundation
import Flutter

/** A listener that can listen to the task lifecycle events. */
public protocol FlutterForegroundTaskLifecycleListener : AnyObject {
  /**
   * Each time a task starts, a new FlutterEngine is created.
   *
   * This is called before onTaskStart, Initialize the service you want to use in the task. (like PlatformChannel initialization)
   */
  func onEngineCreate(flutterEngine: FlutterEngine?)
  
  /** Called when the task is started. */
  func onTaskStart(starter: FlutterForegroundTaskStarter)

  /** Called based on the eventAction set in ForegroundTaskOptions. */
  func onTaskRepeatEvent()
  
  /** Called when the task is destroyed. */
  func onTaskDestroy()
  
  /**
   * If one task is finished or replaced by another, the FlutterEngine is destroyed.
   *
   * This is called after onTaskDestroy, where dispose the service that was initialized in onEngineCreate.
   */
  func onEngineWillDestroy()
}
