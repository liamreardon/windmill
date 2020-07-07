//
//  AuthManager.swift
//  windmill
//
//  Created by Liam  on 2020-04-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit
import SwiftKeychainWrapper

struct AuthManager {
    
    let LOGIN = "/login"
    let SIGNUP = "/signup"
    
    func login(params: [String:Any]) {
        
        if let url = URL(string: Environment.rootURL+"/api/auth"+LOGIN) {
            
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
                                let storyboard = UIStoryboard(name: "UserCreation", bundle: nil)
                                let vc = storyboard.instantiateViewController(withIdentifier: "usernameCreation") as UIViewController
                                vc.modalPresentationStyle = .fullScreen
                                UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
                            }

                        }
                        else {
                            // Login user
                            DispatchQueue.main.async {
                                let username = json["username"] as! String
                                let userId = json["userId"] as! String
                                let followers = json["followers"] as! [String]
                                let following = json["following"] as! [String]
                                let numFollowers = json["numFollowers"] as! Int
                                let numFollowing = json["numFollowing"] as! Int
                                let dp = json["displayPicture"] as! String
                                KeychainWrapper.standard.set(username, forKey: "username")
                                KeychainWrapper.standard.set(userId, forKey: "userId")
                                UserDefaults.standard.set(followers, forKey: "followers")
                                UserDefaults.standard.set(following, forKey: "following")
                                UserDefaults.standard.set(numFollowers, forKey: "numFollowers")
                                UserDefaults.standard.set(numFollowing, forKey: "numFollowing")
                                UserDefaults.standard.set(dp, forKey: "dp")
                                let storyboard = UIStoryboard(name: "WindmillMain", bundle: nil)
                                let vc = storyboard.instantiateViewController(withIdentifier: "tabBarController") as UIViewController
                                vc.modalPresentationStyle = .fullScreen
                                UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
                            }
                        }
                    }
                } catch let error {
                    print("error",error.localizedDescription)
                }
            }
            task.resume()
        }
            
    }
    
    func signup(data:[String:Any]) -> ([String:Any]) {
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: ([String:Any]) = (["":""])
        
        if let url = URL(string: Environment.rootURL+"/api/auth"+SIGNUP) {
            
            let session = URLSession.shared
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            } catch let error {
                result = (["error":error.localizedDescription])
                print(error.localizedDescription)
            }
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
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
                        
                        result = json
                        
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
