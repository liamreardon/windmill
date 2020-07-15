//
//  CommentCell.swift
//  windmill
//
//  Created by Liam  on 2020-07-06.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

class CommentCell: UITableViewCell {
    
    // MARK: IVARS
    
    @IBOutlet weak var commentImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    internal var comment: Comment!
    
    func update(for comment: Comment) {
        self.comment = comment
        if comment.verified! {
            let fullString = NSMutableAttributedString(string: comment.username!)
            let image1Attachment = NSTextAttachment()
            let icon = UIImage(systemName: "checkmark.seal.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))?.withTintColor(UIColor(rgb: 0x1bc9fc), renderingMode: .alwaysOriginal)
            image1Attachment.image = icon
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            usernameLabel.attributedText = fullString
        }
            
        else {
            usernameLabel.text = comment.username
        }
        
        commentLabel.text = comment.commentData
        
        commentImage.contentMode = UIView.ContentMode.scaleAspectFill
        
        commentImage.layer.cornerRadius = commentImage.frame.height / 2
    
        commentImage.sd_setImage(with: URL(string: comment.displayPicture!), placeholderImage: UIImage(named: ""))
    }
    
}
