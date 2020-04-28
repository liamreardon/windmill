//
//  ProfileCreation.swift
//  windmill
//
//  Created by Liam  on 2020-04-27.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

class ProfileCreationViewController: UIViewController {
    
    let authManager = AuthManager()
    var imagePicker: ImagePicker!
    let defaults = UserDefaults.standard
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
    }
    
    @IBAction func setUsername(_ sender: Any) {
        
        if let tokenId = defaults.string(forKey: "token") {
            let data: [String:Any] = [
                "username":usernameTextField.text!,
                "userToken": ["tokenId": tokenId]
            ]
            
            let result = authManager.checkUsername(data: data)
            
            if result["available"] as? Int == 1 {
                // Username available
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
    }
}
