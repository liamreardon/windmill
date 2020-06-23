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
    var verified: Bool?
    var username: String?
    var caption: String?
    var numlikes: Int?
    var likers: [String]?
    var url: String?
    var thumbnail: String?
    var dateAdded: String?
    
    init?(dictionary: [String: Any]) {
        let id = dictionary["postid"] as? String
        let userId = dictionary["userid"] as? String
        let verified = dictionary["verified"] as? Bool
        let username = dictionary["username"] as? String
        let caption = dictionary["caption"] as? String
        let numlikes = dictionary["numlikes"] as? Int
        let likers = dictionary["likers"] as? [String]
        let url = dictionary["url"] as? String
        let thumbnail = dictionary["thumbnail"] as? String
        let dateAdded = dictionary["dateadded"] as? String
      
        self.id = id
        self.userId = userId
        self.verified = verified
        self.username = username
        self.caption = caption
        self.numlikes = numlikes
        self.likers = likers
        self.url = url
        self.thumbnail = thumbnail
        self.dateAdded = dateAdded
    }
}

