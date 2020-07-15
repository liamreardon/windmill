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
    
    let API_URL = Environment.rootURL+"/api/feed/"
    
    func getUserFeed(username: String, completionHandler: @escaping (_ data: Data?) -> Void) {
        if let url = URL(string: API_URL+username) {
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
    
    func getAllFeed(username: String, completionHandler: @escaping (_ data: Data?) -> Void) {
        if let url = URL(string: API_URL+username+"/all") {
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
