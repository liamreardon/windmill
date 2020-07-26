//
//  NSObject.swift
//  windmill
//
//  Created by Liam  on 2020-07-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation

extension NSObject {
  func safeRemoveObserver(_ observer: NSObject, forKeyPath keyPath: String) {
    switch self.observationInfo {
    case .some:
      self.removeObserver(observer, forKeyPath: keyPath)
    default:
      debugPrint("observer does no not exist")
    }
  }
}
