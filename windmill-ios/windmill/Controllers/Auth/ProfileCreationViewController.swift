//
//  ProfileCreationViewController.swift
//  windmill
//
//  Created by Liam  on 2020-04-30.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit
import SwiftKeychainWrapper

class ProfileCreationViewController: UIViewController {
    
    let authManager = AuthManager()
    let uploadManager = UploadManager()
    var imagePicker: ImagePicker!
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }
    
    @IBAction func setUsername(_ sender: Any) {
        
        if let tokenId = KeychainWrapper.standard.string(forKey: "token") {
            let data: [String:Any] = [
                "username":usernameTextField.text!,
                "userToken": ["tokenId": tokenId]
            ]
            
            let result = authManager.signup(data: data)
            
            if result["available"] as? Int == 1 {
                // Username available
                let username = usernameTextField.text!
                let userId = result["userId"] as! String
                KeychainWrapper.standard.set(username, forKey: "username")
                KeychainWrapper.standard.set(userId, forKey: "userId")
                self.performSegue(withIdentifier: "toProfilePic", sender: nil)
                
            }
            else {
                // Username taken
                let alert = UIAlertController(title: "Oops", message: "Username is taken, try again!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
        }
        
    
    }
    
    @IBAction func uploadImageTapped(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBAction func dismissUploadTapped(_ sender: Any) {
        print("redirecting to home...")
    }
    
}

extension ProfileCreationViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        self.profilePictureImageView.image = image
        uploadManager.uploadProfilePicture(image: profilePictureImageView.image!)
    }
}
