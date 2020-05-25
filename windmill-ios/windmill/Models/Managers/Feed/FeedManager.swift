//
//  FeedManager.swift
//  windmill
//
//  Created by Liam  on 2020-05-14.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

struct FeedManager {
    
    let API_URL = "http://liam.local:8080/api/feed/"
    
    func getUserFeed(userId: String, completionHandler: @escaping (_ data: Data?) -> Void) {
        if let userId = KeychainWrapper.standard.string(forKey: "userId") {
            if let url = URL(string: API_URL+userId) {
                let session = URLSession.shared
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    if let data = data {
                        completionHandler(data)
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                })
                task.resume()
                
            }
        }
    }
    
    
    
}
