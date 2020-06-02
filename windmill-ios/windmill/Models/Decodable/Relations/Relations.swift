//
//  Relations.swift
//  windmill
//
//  Created by Liam  on 2020-06-02.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation

struct Relations: Decodable {
    var followers: [String]?
    var following: [String]?
    var likedposts: [String]?
    
     init?(dictionary: [String: Any]) {
         
        let followers = dictionary["followers"] as? [String]
        let following = dictionary["following"] as? [String]
        let likedposts = dictionary["likedposts"] as? [String]
        
        self.followers = followers
        self.following = following
        self.likedposts = likedposts
    
     }
}
