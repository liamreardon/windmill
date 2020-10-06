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
      static let bucketURL = "BUCKET_URL"
    }
  }

  // MARK: - Plist
  private static let infoDictionary: NSDictionary? = {
    var dict: NSDictionary?
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist") {
      dict = NSDictionary(contentsOfFile: path)
    }
    else {
        fatalError("Plist file not found")
    }
    return dict!
  }()

  // MARK: - Plist values
  static let rootURL: String = {
    guard let url = Environment.infoDictionary?[Keys.Plist.rootURL] as? String else {
      fatalError("Root URL not set in plist for this environment")
    }
    return url
  }()

  static let googleClientId: String = {
    guard let googleClientId = Environment.infoDictionary?[Keys.Plist.googleClientId] as? String else {
      fatalError("API Key not set in plist for this environment")
    }
    return googleClientId
  }()
    
  static let bucketURL: String = {
    guard let bucketURL = Environment.infoDictionary?[Keys.Plist.bucketURL] as? String else {
      fatalError("Bucket URL not set in plist for this environment")
    }
    return bucketURL
  }()
  
}
