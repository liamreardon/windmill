//
//  UserManager.swift
//  windmill
//
//  Created by Liam  on 2020-05-13.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

struct UserManager {
    
    let API_URL = Environment.rootURL+"/api/user/"
    func getUserDisplayPicture(userId: String, completionHandler: @escaping (_ data: Data?) -> Void) {
        if let url = URL(string: API_URL+userId+"/dp") {
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
    
    func updateUserFollowingStatus(username: String, followingUsername: String, followingStatus: Bool, completionHandler: @escaping (_ data: Data?) -> Void) {
        if let url = URL(string: API_URL+username+"/following/"+followingUsername+"/"+String(followingStatus)) {
            let session = URLSession.shared
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
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
    
    func getUser(username: String, completionHandler: @escaping (_ data: Data?) -> Void) {
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
    
    
    
}
