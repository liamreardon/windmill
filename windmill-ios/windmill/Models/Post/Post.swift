//
//  Post.swift
//  windmill
//
//  Created by Liam  on 2020-05-16.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation

struct Post: Decodable {
    var id: String?
    var userId: String?
    var numlikes: Int?
    var likers: [String]?
    var url: String?
    
    init?(dictionary: [String: Any]) {
        let id = dictionary["id"] as? String
        let userId = dictionary["userid"] as? String
        let numlikes = dictionary["numlikes"] as? Int
        let likers = dictionary["likers"] as? [String]
        let url = dictionary["url"] as? String
      
        self.id = id
        self.userId = userId
        self.numlikes = numlikes
        self.likers = likers
        self.url = url
    }
}

