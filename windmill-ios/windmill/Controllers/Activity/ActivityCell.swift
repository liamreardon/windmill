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
    
    func update(for activity: Activity) {
        activityLabel.text = activity.body
        activityImage.layer.borderWidth = 1.6
        activityImage.layer.borderColor = UIColor.white.cgColor
        activityImage.contentMode = UIView.ContentMode.scaleAspectFill
        
        if activity.type == "FOLLOWED" {
            activityImage.layer.cornerRadius = activityImage.frame.height / 2
        }

        activityImage.sd_setImage(with: URL(string: activity.image!), placeholderImage: UIImage(named: ""))
    }
    
}
