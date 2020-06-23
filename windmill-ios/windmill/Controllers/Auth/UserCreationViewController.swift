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
import Pastel

class UserCreationViewController: UIViewController {
    
    let authManager = AuthManager()
    let uploadManager = UploadManager()
    let storageManager = StorageManager()
    var imagePicker: ImagePicker!
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var displayPictureImageView: UIImageView!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePicker = ImagePicker(presentationController: self, delegate: self, mediaType: "public.image")
        setupUI()
    }
    
    // MARK: User Interaction
    
    @IBAction func setUsername(_ sender: Any) {
        
        if let tokenId = KeychainWrapper.standard.string(forKey: "token") {
            let data: [String:Any] = [
                "username":usernameTextField.text!,
                "userToken": ["tokenId": tokenId]
            ]
            
            let result = authManager.signup(data: data)
            
            if result["available"] as? Int == 1 {
                // Username available
                print(result)
                let username = usernameTextField.text!
                let userId = result["userId"] as! String
                let followers = result["followers"] as! [String]
                let following = result["following"] as! [String]
                let numFollowers = result["numFollowers"] as! Int
                let numFollowing = result["numFollowing"] as! Int
                KeychainWrapper.standard.set(username, forKey: "username")
                KeychainWrapper.standard.set(userId, forKey: "userId")
                UserDefaults.standard.set(followers, forKey: "followers")
                UserDefaults.standard.set(following, forKey: "following")
                UserDefaults.standard.set(numFollowers, forKey: "numFollowers")
                UserDefaults.standard.set(numFollowing, forKey: "numFollowing")
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
        self.goToHome()
    }
    
    @IBAction func saveDisplayPicture(_ sender: Any) {
        let userId = KeychainWrapper.standard.string(forKey: "userId") 
        self.storageManager.store(image: displayPictureImageView.image!, forKey: userId!+"displayPicture", withStorageType: .fileSystem)
        uploadManager.uploadProfilePicture(image: displayPictureImageView.image!)
        self.goToHome()
        
    }
    
    // MARK: User Interface
    func setupUI() {
        let pastelView = PastelView(frame: view.bounds)
        pastelView.startPastelPoint = .bottomLeft
        pastelView.endPastelPoint = .topRight
        pastelView.setColors([UIColor(red: 90/255, green: 120/255, blue: 127/255, alpha: 1.0),
                              UIColor(red: 58/255, green: 255/255, blue: 217/255, alpha: 1.0),
                              UIColor(red: 156/255, green: 39/255, blue: 176/255, alpha: 1.0),
                              UIColor(red: 255/255, green: 64/255, blue: 129/255, alpha: 1.0),
                              UIColor(red: 123/255, green: 31/255, blue: 162/255, alpha: 1.0),
                              UIColor(red: 32/255, green: 76/255, blue: 255/255, alpha: 1.0),
                              UIColor(red: 32/255, green: 158/255, blue: 255/255, alpha: 1.0)])
        pastelView.startAnimation()
        view.insertSubview(pastelView, at: 0)
    }
    
    
    // MARK: Segue
    
    func goToHome() {
        let storyboard = UIStoryboard(name: "WindmillMain", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "tabBarController") as UIViewController
        vc.modalPresentationStyle = .fullScreen
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
    
}

extension UserCreationViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        if image == nil { return }
        self.displayPictureImageView.image = image
    }
    
    func didSelectVideo(url: URL?) {
        
    }
}



