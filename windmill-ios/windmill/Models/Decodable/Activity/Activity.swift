//
//  Activity.swift
//  windmill
//
//  Created by Liam  on 2020-06-23.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation

struct Activity: Decodable {
    var id: String?
    var type: String?
    var username: String?
    var post: Post?
    var comment: Comment?
    var body: String?
    var image: String?
    
     init?(dictionary: [String: Any]) {
         
        let id = dictionary["id"] as? String
        let type = dictionary["type"] as? String
        let username = dictionary["username"] as? String
        let body = dictionary["body"] as? String
        let image = dictionary["image"] as? String
        
        self.id = id
        self.type = type
        self.username = username
        self.body = body
        self.image = image
        self.post = nil
        self.comment = nil
    
     }
}
