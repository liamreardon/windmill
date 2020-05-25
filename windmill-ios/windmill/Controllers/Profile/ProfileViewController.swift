//
//  ProfileViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-05.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import GoogleSignIn
import SwiftKeychainWrapper

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var displayPicture: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    let userManager = UserManager()
    let storageManager = StorageManager()
    let feedManager = FeedManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getUserDetails()
        self.initSignOutButton()
        self.initGraphics()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.getDisplayPicture()
        self.getUserFeed()
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    @objc func signOut(_ sender: UIButton) {
        print("signing out...")
        GIDSignIn.sharedInstance()?.signOut()
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "loginMain") as UIViewController
            vc.modalPresentationStyle = .fullScreen
            UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
        }
        
    }
    
    func getDisplayPicture() {
        let userId = KeychainWrapper.standard.string(forKey: "userId")
        let image = storageManager.retrieveImage(forKey: userId!+"displayPicture", inStorageType: .fileSystem)
        if image == nil {
            userManager.getUserDisplayPicture { (data) in
                DispatchQueue.main.async {
                    let retrievedImage = UIImage(data: data!)
                    if retrievedImage != nil {
                        self.displayPicture.image = image
                        self.storageManager.store(image: retrievedImage!, forKey: userId!+"displayPicture", withStorageType: .fileSystem)
                    }
                }
            }
        }
        else {
            self.displayPicture.image = image
        }

    }
    
    func getUserDetails() {
        usernameLabel.text = KeychainWrapper.standard.string(forKey: "username")
    }
    
    func initSignOutButton() {
        GIDSignIn.sharedInstance()?.presentingViewController = self
        let googleSignOut = UIButton(frame: CGRect(x: 50, y: 50, width: 100, height: 30))
        googleSignOut.backgroundColor = UIColor.red
        googleSignOut.setTitle("Sign Out", for: .normal)
        googleSignOut.center = view.center
        googleSignOut.center.y = view.center.y + 100
        googleSignOut.addTarget(self, action: #selector(self.signOut(_:)), for: .touchUpInside)
        self.view.addSubview(googleSignOut)
    }
    
    func initGraphics() {
        displayPicture.layer.borderWidth = 1
        displayPicture.layer.masksToBounds = false
        displayPicture.layer.borderColor = UIColor.black.cgColor
        displayPicture.layer.cornerRadius = displayPicture.frame.height / 2
        displayPicture.clipsToBounds = true
    }
    
    func getUserFeed() {
        let userId = KeychainWrapper.standard.string(forKey: "userId")
        feedManager.getUserFeed(userId: userId!) { (data) in
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                    print(json)
                }
            } catch let error {
                print("failed to load posts", error.localizedDescription)
            }
        }
    }
    
    
}
