//
//  PostManager.swift
//  windmill
//
//  Created by Liam  on 2020-05-25.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation

import SwiftKeychainWrapper

struct PostManager {
    
    let API_URL = Environment.rootURL+"/api/user/"
    let boundary = "Boundary-\(NSUUID().uuidString)"
    
    func likeRequest(postUserId: String, userId: String, postId: String, likedStatus: Bool, completionHandler: @escaping (_ data: Data?) -> Void) {
        
        if let url = URL(string: API_URL+postUserId+"/post/"+postId+"/likers/"+userId+"/"+String(likedStatus)) {
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
    
    func userCommentedOnPostRequest(postUserId: String, userId: String, postId: String, comment: String, completionHandler: @escaping (_ data: Data?) -> Void) {
        if let url = URL(string: API_URL+postUserId+"/post/"+postId+"/comments/"+userId) {
            let session = URLSession.shared
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let parameters: [String: Any] = [
                
                "comment" : comment
            
            ]
            
            let body = NSMutableData()
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions.prettyPrinted)
                body.append(jsonData)
       
            } catch let error {
                print(error.localizedDescription)
            }
            
            request.httpBody = body as Data
            
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
    
    func getPostComments(postUserId: String, postId: String, completionHandler: @escaping (_ data: Data?) -> Void) {
        if let url = URL(string: API_URL+postUserId+"/post/"+postId+"/comments") {
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

