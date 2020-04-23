//
//  AuthManager.swift
//  windmill
//
//  Created by Liam  on 2020-04-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation


struct AuthManager {
    
    let API_URL = "http://localhost:8080/api/auth"
    let LOGIN = "/login"
    let SIGNUP = "/signup"
    
    func login(params: [String:Any]) {
        if let url = URL(string: API_URL+LOGIN) {
            
            let session = URLSession.shared
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
            }
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
                guard error == nil else {
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any] {
                        
                        print(json)
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
            task.resume()
        }
            
    }
    
}
