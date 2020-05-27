//
//  UploaderManager.swift
//  windmill
//
//  Created by Liam  on 2020-04-30.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import SwiftKeychainWrapper

struct UploadManager {
    
    let API_URL = "http://liam.local:8080/api/user/"
    let boundary = "Boundary-\(NSUUID().uuidString)"
    
    func uploadProfilePicture(image: UIImage) {
        
        if let userId = KeychainWrapper.standard.string(forKey: "userId") {
            if let url = URL(string: API_URL+userId+"/dp") {
                
                let session = URLSession.shared
                
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                let imageData = image.jpegData(compressionQuality: 1)
                
                if (imageData == nil) {
                    print("UIImageJPEGRepresentation return nil")
                    return
                }
                
                let filename = "displaypic.jpg"

                let body = NSMutableData()
                body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
                body.append(NSString(format: "Content-Disposition: form-data; name=\"token\"\r\n\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
                body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
                body.append("Content-Disposition:form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: String.Encoding.utf8)!)
                body.append(NSString(format: "Content-Type: application/octet-stream\r\n\r\n").data(using: String.Encoding.utf8.rawValue)!)
                body.append(imageData!)
                body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)

                
                request.httpBody = body as Data

                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    if let data = data {
                        // handle
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                })
                task.resume()
            }
        }
    }
    
    func uploadVideo(videoURL: URL) {
        if let userId = KeychainWrapper.standard.string(forKey: "userId") {
            if let url = URL(string: API_URL+userId+"/posts") {
                
                let session = URLSession.shared

                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                
                var movieData: Data?
                do {
                    movieData = try Data(contentsOf: videoURL, options: Data.ReadingOptions.alwaysMapped)
                } catch _ {
                    movieData = nil
                    return
                }

                let body = NSMutableData()

                // change file name whatever you want
                let filename = "upload.mov"
                let mimetype = "video/mov"
                
                body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
                body.append(NSString(format: "Content-Disposition: form-data; name=\"token\"\r\n\r\n" as NSString).data(using: String.Encoding.utf8.rawValue)!)
                body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
                body.append("Content-Disposition:form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: String.Encoding.utf8)!)
                body.append("Content-Type: \(mimetype)\r\n\r\n".data(using: String.Encoding.utf8)!)
                body.append(movieData!)
                body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
                request.httpBody = body as Data
                
                let task = session.dataTask(with: request as URLRequest, completionHandler: {
                    (data, response, error) -> Void in
                    if let _ = data {
                        // call reload data 
                    } else if let error = error {
                        print(error.localizedDescription)
                    }
                })
                task.resume()
                
            }
        }
    }
}
