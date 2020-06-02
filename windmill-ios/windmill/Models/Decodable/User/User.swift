//
//  User.swift
//  windmill
//
//  Created by Liam  on 2020-06-02.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation

struct User: Decodable {
    
    var username: String?
    var displayname: String?
    var displaypicture: String?
    var verified: Bool?
    var relations: Relations?
    var posts: [Post]?
    
    init?(dictionary: [String: Any]) {
        
        let username = dictionary["username"] as? String
        let displayname = dictionary["displayName"] as? String
        let displaypicture = dictionary["displayPicture"] as? String
        let verified = dictionary["verified"] as? Bool

        self.username = username
        self.displayname = displayname
        self.displayname = displaypicture
        self.verified = verified
        self.posts = []
        
    }
}
