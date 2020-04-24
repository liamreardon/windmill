//
//  Environment.swift
//  windmill
//
//  Created by Liam  on 2020-04-23.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation

public enum Environment {
  // MARK: - Keys
  enum Keys {
    enum Plist {
      static let rootURL = "ROOT_URL"
      static let googleClientId = "GOOGLE_CLIENT_ID"
    }
  }

  // MARK: - Plist
  private static let infoDictionary: [String: Any] = {
    guard let dict = Bundle.main.infoDictionary else {
      fatalError("Plist file not found")
    }
    return dict
  }()

  // MARK: - Plist values
  static let rootURL: URL = {
    guard let rootURLstring = Environment.infoDictionary[Keys.Plist.rootURL] as? String else {
      fatalError("Root URL not set in plist for this environment")
    }
    guard let url = URL(string: rootURLstring) else {
      fatalError("Root URL is invalid")
    }
    return url
  }()

  static let googleClientId: String = {
    guard let googleClientId = Environment.infoDictionary[Keys.Plist.googleClientId] as? String else {
      fatalError("API Key not set in plist for this environment")
    }
    return googleClientId
  }()
}
