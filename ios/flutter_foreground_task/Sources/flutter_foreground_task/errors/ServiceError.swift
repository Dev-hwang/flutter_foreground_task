//
//  ServiceError.swift
//  flutter_foreground_task
//
//  Created by Woo Jin Hwang on 7/17/24.
//

import Foundation

enum ServiceError {
  case ServiceArgumentNullException
  case ServiceAlreadyStartedException
  case ServiceNotStartedException
  case ServiceNotSupportedException
}

extension ServiceError : LocalizedError {
  public var errorDescription: String? {
    switch self {
      case .ServiceArgumentNullException:
        return NSLocalizedString("The required argument was not passed to the service.", comment: "ServiceArgumentNullException")
      case .ServiceAlreadyStartedException:
        return NSLocalizedString("The service has already started.", comment: "ServiceAlreadyStartedException")
      case .ServiceNotStartedException:
        return NSLocalizedString("The service is not started.", comment: "ServiceNotStartedException")
      case .ServiceNotSupportedException:
        return NSLocalizedString("The current iOS version does not support the service.", comment: "ServiceNotSupportedException")
    }
  }
}
