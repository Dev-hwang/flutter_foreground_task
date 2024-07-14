//
//  FlutterForegroundTaskLifecycleListener.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 7/15/24.
//

import Foundation
import Flutter

/**
 * A listener that can listen to the task lifecycle events.
 *
 * It has the same meaning as the TaskHandler callback function on the Dart side.
 */
public protocol FlutterForegroundTaskLifecycleListener {
  /**
   * Called before onTaskStart is called.
   *
   * You can do some initialization before the task starts. (like MethodChannel and internal plug-in initialization)
   */
  func onCreateFlutterEngine(flutterEngine: FlutterEngine?)
  
  /** Called when the task is started. */
  func onTaskStart()
  
  /** Called every interval milliseconds in ForegroundTaskOptions. */
  func onTaskRepeatEvent()
  
  /** Called when the task is destroyed. */
  func onTaskDestroy()
  
  /**
   * Called after onTaskDestroy is called.
   *
   * Dispose the services initialized in onCreateFlutterEngine.
   */
  func onDestroyFlutterEngine()
}
