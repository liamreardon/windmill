//
//  ActivityCell.swift
//  windmill
//
//  Created by Liam  on 2020-06-23.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

class ActivityCell: UITableViewCell {
    
    // MARK: IVARS
    
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var activityImage: UIImageView!
    internal var activity: Activity!
    let userManager = UserManager()
    
    func update(for activity: Activity) {
        self.activity = activity
        activityLabel.text = activity.body
        activityImage.layer.borderWidth = 1.6
        activityImage.layer.borderColor = UIColor.white.cgColor
        activityImage.contentMode = UIView.ContentMode.scaleAspectFill
        
        if activity.type == "FOLLOWED" {
            activityImage.layer.cornerRadius = activityImage.frame.height / 2
            userManager.getUser(username: activity.username!) { (data) in
                do {
                    let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                    let user = jsonResponse["user"] as! [String:Any]
                    let usr = User(dictionary: user)!
                    self.activityImage.sd_setImage(with: URL(string: usr.displaypicture!), placeholderImage: UIImage(named: ""))
                } catch let error {
                    print(error.localizedDescription)
                }

            }
        }
        else {
            activityImage.sd_setImage(with: URL(string: activity.post!.thumbnail!), placeholderImage: UIImage(named: ""))
        }
    }
}
