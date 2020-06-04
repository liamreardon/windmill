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
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    
    var currentUserProfile: Bool = true
    var followingUser: User?
    var isFollowing: Bool? = false
    
    var numberOfFollowers: Int = 0
    var numberOfFollowing: Int = 0
    
    let userManager = UserManager()
    let storageManager = StorageManager()
    let feedManager = FeedManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if currentUserProfile {
            getUserDetails()
            initSignOutButton()
            initGraphics()
        }
        else {
            loadUserData()
            initGraphics()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if currentUserProfile {
            getUserDetails()
            getDisplayPicture()
            getUserFeed()
            initGraphics()
        }
        else {
            initGraphics()
            loadUserData()
        }

    }
    
    // MARK: User Interaction
    
    @IBAction func followButtonTapped(_ sender: Any) {
        isFollowing! = !isFollowing!
        let username = KeychainWrapper.standard.string(forKey: "username")
        var following = UserDefaults.standard.stringArray(forKey: "following") ?? [String]()
        let numFollowing = UserDefaults.standard.integer(forKey: "numFollowing")
 
        if isFollowing! {
            following.append(followingUser!.username!)
            userManager.updateUserFollowingStatus(username: username!, followingUsername: followingUser!.username!, followingStatus: true) { (data) in
                UserDefaults.standard.set(following, forKey: "following")
                UserDefaults.standard.set(numFollowing + 1, forKey: "numFollowers")
            }
            
            followButton.setTitle("Unfollow", for: .normal)
            numberOfFollowers += 1
            followersLabel.text = "followers: " + String(numberOfFollowers)
            
        }
        else {
            let newFollowing = following.filter {$0 != followingUser?.username}
            userManager.updateUserFollowingStatus(username: username!, followingUsername: followingUser!.username!, followingStatus: false) { (data) in
                UserDefaults.standard.set(newFollowing, forKey: "following")
                UserDefaults.standard.set(numFollowing - 1, forKey: "numFollowers")
            }
            
            followButton.setTitle("Follow", for: .normal)
            numberOfFollowers -= 1
            followersLabel.text = "followers: " + String(numberOfFollowers)
        }
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
    
    // MARK: Current User Setup
    
    func getDisplayPicture() {
        let userId = KeychainWrapper.standard.string(forKey: "userId")
        let image = storageManager.retrieveImage(forKey: userId!+"displayPicture", inStorageType: .fileSystem)
        if image == nil {
            userManager.getUserDisplayPicture(userId: userId!) { (data) in
                DispatchQueue.main.async {
                    let retrievedImage = UIImage(data: data!)
                    if retrievedImage != nil {
                        self.displayPicture.image = retrievedImage
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
        numberOfFollowers = UserDefaults.standard.integer(forKey: "numFollowers")
        numberOfFollowing = UserDefaults.standard.integer(forKey: "numFollowing")
        followersLabel.text = "followers: " + String(numberOfFollowers)
        followingLabel.text = "following: " + String(numberOfFollowing)
        followButton.isHidden = true
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
                    // user feed
                }
            } catch let error {
                print("failed to load posts", error.localizedDescription)
            }
        }
    }
    
    // MARK: Following User Setup
    func loadUserData() {
       
        let BUCKET_URL = Environment.bucketURL
        if followingUser?.displaypicture != nil {
            let url = URL(string: BUCKET_URL+followingUser!.displaypicture!)
            displayPicture.load(url: url!)
        }
        
        usernameLabel.text = followingUser?.username
        isFollowing = isUserFollowing()
        if isFollowing! {
            followButton.setTitle("Unfollow", for: .normal)
        }
        else {
            followButton.setTitle("Follow", for: .normal)
        }
        
        numberOfFollowers = followingUser!.relations!.followers!.count
        
        followersLabel.text = "followers: " + String(followingUser!.relations!.followers!.count)
        followingLabel.text = "following: " + String(followingUser!.relations!.following!.count)

    }
    
    func isUserFollowing() -> Bool {
        let following = UserDefaults.standard.stringArray(forKey: "following") ?? [String]()
        for i in 0 ..< following.count {
            if following[i] == followingUser!.username! {
                return true
            }
        }
        return false
    }

}
