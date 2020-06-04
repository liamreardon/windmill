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
    
}

