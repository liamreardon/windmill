//
//  AuthManager.swift
//  windmill
//
//  Created by Liam  on 2020-04-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

enum NetworkError: Error {
    case badURL
}

struct AuthManager {
    
    let API_URL = "http://localhost:8080/api/auth"
    let LOGIN = "/login"
    let SIGNUP = "/signup"
    
    let loginViewController = LoginViewController()
    
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
                        if json["authFlag"] as? String == "1" {
                            // Redirect user to username creation
                            DispatchQueue.main.async {
                                let storyboard = UIStoryboard(name: "ProfileCreation", bundle: nil)
                                let vc = storyboard.instantiateViewController(withIdentifier: "usernameCreation") as UIViewController
                                UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
                            }

                        }
                        else {
                            // Login user
                        }
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            }
            task.resume()
        }
            
    }
    
    func checkUsername(username:[String:String]) -> ([String:Any]) {
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: ([String:Any]) = (["":""])
        
        if let url = URL(string: API_URL+SIGNUP) {
            
            let session = URLSession.shared
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: username, options: .prettyPrinted)
            } catch let error {
                result = (["error":error.localizedDescription])
                print(error.localizedDescription)
            }
            
            let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
                guard error == nil else {
                    result = (["error":"network error"])
                    return
                }
                
                guard let data = data else {
                    result = (["error":"network error"])
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:Any] {
                         result = (json)
                     }
                } catch let error {
                    result = (["error":error.localizedDescription])
                    print(error.localizedDescription)
                }
                
                semaphore.signal()
            }
            task.resume()
        }
        
        _ = semaphore.wait(wallTimeout: .distantFuture)
        return result
    }
    
}
