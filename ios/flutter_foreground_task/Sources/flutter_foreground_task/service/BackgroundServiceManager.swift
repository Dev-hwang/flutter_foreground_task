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
      
      BackgroundServiceStatus.setData(action: BackgroundServiceAction.API_START)
      NotificationOptions.setData(args: args)
      NotificationContent.setData(args: args)
      ForegroundTaskOptions.setData(args: args)
      ForegroundTaskData.setData(args: args)
      BackgroundService.sharedInstance.run()
    } else {
      throw ServiceError.ServiceNotSupportedException
    }
  }
  
  func restart(arguments: Any?) throws {
    if #available(iOS 10.0, *) {
      if !BackgroundService.sharedInstance.isRunningService {
        throw ServiceError.ServiceNotStartedException
      }
      
      BackgroundServiceStatus.setData(action: BackgroundServiceAction.API_RESTART)
      BackgroundService.sharedInstance.run()
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
      
      BackgroundServiceStatus.setData(action: BackgroundServiceAction.API_UPDATE)
      NotificationContent.updateData(args: args)
      ForegroundTaskOptions.updateData(args: args)
      ForegroundTaskData.updateData(args: args)
      BackgroundService.sharedInstance.run()
    } else {
      throw ServiceError.ServiceNotSupportedException
    }
  }
  
  func stop() throws {
    if #available(iOS 10.0, *) {
      if !BackgroundService.sharedInstance.isRunningService {
        throw ServiceError.ServiceNotStartedException
      }
      
      BackgroundServiceStatus.setData(action: BackgroundServiceAction.API_STOP)
      NotificationOptions.clearData()
      NotificationContent.clearData()
      ForegroundTaskOptions.clearData()
      ForegroundTaskData.clearData()
      BackgroundService.sharedInstance.run()
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
