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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getUserDetails()
        self.initSignOutButton()
        self.initGraphics()
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
    
    func getUserDetails() {
        usernameLabel.text = KeychainWrapper.standard.string(forKey: "username")
        userManager.getUserDisplayPicture { (data) in
            DispatchQueue.main.async {
                let image = UIImage(data: data!)
                self.displayPicture.image = image
            }
        }
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
}
