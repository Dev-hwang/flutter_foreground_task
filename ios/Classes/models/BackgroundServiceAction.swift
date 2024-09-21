//
//  BackgroundServiceAction.swift
//  flutter_foreground_task
//
//  Created by WOO JIN HWANG on 2021/08/11.
//

import Foundation

enum BackgroundServiceAction: String {
  case API_START
  case API_RESTART
  case API_UPDATE
  case API_STOP
  
  case APP_TERMINATE
}
