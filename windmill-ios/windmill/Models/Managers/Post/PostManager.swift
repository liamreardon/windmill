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
    
    let API_URL = "http://liam.local:8080/api/user/"
    
    func likeRequest(userId: String, postId: String, likedStatus: Bool, completionHandler: @escaping (_ data: Data?) -> Void) {
        
        if let url = URL(string: API_URL+userId+"/post/"+postId+"/"+String(likedStatus)) {
            print(url)
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

