//
//  BackgroundServiceManager.swift
//  flutter_foreground_task
//
//  Created by WOO JIN HWANG on 2021/08/10.
//

import Flutter
import Foundation

class BackgroundServiceManager: NSObject {
  func start(arguments: Any?) throws {
    if #available(iOS 10.0, *) {
      if BackgroundService.sharedInstance.isRunningService {
        throw ServiceError.ServiceAlreadyStartedException
      }

      guard let args = arguments as? Dictionary<String, Any> else {
        throw ServiceError.ServiceArgumentNullException
      }
      NotificationOptions.setData(args: args)
      NotificationContent.setData(args: args)
      BackgroundTaskOptions.setData(args: args)
      BackgroundTaskData.setData(args: args)
      
      BackgroundService.sharedInstance.run(action: BackgroundServiceAction.START)
    } else {
      throw ServiceError.ServiceNotSupportedException
    }
  }
  
  func restart(arguments: Any?) throws {
    if #available(iOS 10.0, *) {
      if !BackgroundService.sharedInstance.isRunningService {
        throw ServiceError.ServiceNotStartedException
      }
      
      BackgroundService.sharedInstance.run(action: BackgroundServiceAction.RESTART)
    } else {
      throw ServiceError.ServiceNotSupportedException
    }
  }
  
  func update(arguments: Any?) throws {
    if #available(iOS 10.0, *) {
      if !BackgroundService.sharedInstance.isRunningService {
        throw ServiceError.ServiceNotStartedException
      }
      
      guard let args = arguments as? Dictionary<String, Any> else { 
        throw ServiceError.ServiceArgumentNullException
      }
      NotificationContent.updateData(args: args)
      BackgroundTaskOptions.updateData(args: args)
      BackgroundTaskData.updateData(args: args)
      
      BackgroundService.sharedInstance.run(action: BackgroundServiceAction.UPDATE)
    } else {
      throw ServiceError.ServiceNotSupportedException
    }
  }
  
  func stop() throws {
    if #available(iOS 10.0, *) {
      if !BackgroundService.sharedInstance.isRunningService {
        throw ServiceError.ServiceNotStartedException
      }
      
      NotificationOptions.clearData()
      NotificationContent.clearData()
      BackgroundTaskOptions.clearData()
      BackgroundTaskData.clearData()
      
      BackgroundService.sharedInstance.run(action: BackgroundServiceAction.STOP)
    } else {
      throw ServiceError.ServiceNotSupportedException
    }
  }
  
  func sendData(data: Any?) {
    if data != nil {
      BackgroundService.sharedInstance.sendData(data: data)
    }
  }
  
  func isRunningService() -> Bool {
    if #available(iOS 10.0, *) {
      return BackgroundService.sharedInstance.isRunningService
    } else {
      return false
    }
  }
}
