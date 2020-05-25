//
//  UserCreationViewController.swift
//  windmill
//
//  Created by Liam  on 2020-04-30.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit
import SwiftKeychainWrapper

class UserCreationViewController: UIViewController {
    
    let authManager = AuthManager()
    let uploadManager = UploadManager()
    let storageManager = StorageManager()
    var imagePicker: ImagePicker!
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var displayPictureImageView: UIImageView!
    
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
    
    @IBAction func saveDisplayPicture(_ sender: Any) {
        let userId = KeychainWrapper.standard.string(forKey: "userId") 
        self.storageManager.store(image: displayPictureImageView.image!, forKey: userId!+"displayPicture", withStorageType: .fileSystem)
        uploadManager.uploadProfilePicture(image: displayPictureImageView.image!)
        self.goToHome()
        
    }
    
    @IBAction func dismissUploadTapped(_ sender: Any) {
        self.goToHome()
    }
    
    func goToHome() {
        let storyboard = UIStoryboard(name: "WindmillMain", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "tabBarController") as UIViewController
        vc.modalPresentationStyle = .fullScreen
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
    
}

extension UserCreationViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        self.displayPictureImageView.image = image
    }
}



