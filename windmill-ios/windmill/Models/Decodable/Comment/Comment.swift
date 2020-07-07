//
//  Comment.swift
//  windmill
//
//  Created by Liam  on 2020-07-06.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation

struct Comment: Decodable {
    var id: String?
    var username: String?
    var displayPicture: String?
    var commentData: String?
    var date: String?
    var verified: Bool?

     init?(dictionary: [String: Any]) {
         
        let id = dictionary["commentid"] as? String
        let username = dictionary["username"] as? String
        let displayPicture = dictionary["userdisplay"] as? String
        let commentData = dictionary["commentdata"] as? String
        let date = dictionary["dateAdded"] as? String
        let verified = dictionary["verified"] as? Bool
        
        self.id = id
        self.username = username
        self.displayPicture = displayPicture
        self.commentData = commentData
        self.date = date
        self.verified = verified
     }
}
