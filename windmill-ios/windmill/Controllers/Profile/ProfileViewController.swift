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

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: IVARS
    
    @IBOutlet weak var displayPicture: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var currentUserProfile: Bool = true
    var followingUser: User?
    var userProfileThatIsOpen: User?
    var isFollowing: Bool? = false
    
    var numberOfFollowers: Int = 0
    var numberOfFollowing: Int = 0
    
    let userManager = UserManager()
    let storageManager = StorageManager()
    let feedManager = FeedManager()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        if currentUserProfile {
            let username = KeychainWrapper.standard.string(forKey: "username")
            getUser(username: username!)
            getUserDetails()
            initSignOutButton()
            initGraphics()
        }
        else {
            getUser(username: followingUser!.username!)
            loadUserData()
            initGraphics()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if currentUserProfile {
            let username = KeychainWrapper.standard.string(forKey: "username")
            getUser(username: username!)
            getUserDetails()
            getDisplayPicture()
            getUserFeed()
            initGraphics()
        }
        else {
            getUser(username: followingUser!.username!)
            initGraphics()
            loadUserData()
        }
    }
    
    // MARK: User Interaction
    
    @IBAction func followButtonTapped(_ sender: Any) {
        isFollowing! = !isFollowing!
        let username = KeychainWrapper.standard.string(forKey: "username")
        var following = UserDefaults.standard.stringArray(forKey: "following") ?? [String]()
        if isFollowing! {
            following.append(userProfileThatIsOpen!.username!)
            numberOfFollowers += 1
            userManager.updateUserFollowingStatus(username: username!, followingUsername: followingUser!.username!, followingStatus: true) { (data) in
                    UserDefaults.standard.set(following, forKey: "following")
            }
            
            followButton.setTitle("Unfollow", for: .normal)
            
        }
        else {
            numberOfFollowers -= 1
            let newFollowing = following.filter {$0 != userProfileThatIsOpen?.username}
            userManager.updateUserFollowingStatus(username: username!, followingUsername: followingUser!.username!, followingStatus: false) { (data) in
                    UserDefaults.standard.set(newFollowing, forKey: "following")
            }
            
            followButton.setTitle("Follow", for: .normal)
        }
        
        followersLabel.text = "followers: " + String(numberOfFollowers)
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
        
        let username = KeychainWrapper.standard.string(forKey: "username")
        
        if userProfileThatIsOpen!.verified! {
            
            let fullString = NSMutableAttributedString(string: "@\(username!)")
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = UIImage(named: "check.png")
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            usernameLabel.attributedText = fullString
        }
        
        else {
            usernameLabel.text = username!
        }

        numberOfFollowers = userProfileThatIsOpen!.relations!.followers!.count
        numberOfFollowing = userProfileThatIsOpen!.relations!.following!.count
        followersLabel.text = "followers: " + String(numberOfFollowers)
        followingLabel.text = "following: " + String(numberOfFollowing)
        followButton.isHidden = true
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
    
    func getUser(username: String) {
        
        let dGroup = DispatchGroup()
        dGroup.enter()
        userManager.getUser(username: username) { (data) in
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                let user = jsonResponse["user"] as! [String:Any]
                var usr = User(dictionary: user)!
                let posts = user["posts"] as! [[String:Any]]
                for i in 0..<posts.count {
                    let post = Post(dictionary: posts[i])
                    usr.posts!.append(post!)
                }
                
                let relations = user["relations"] as! [String:Any]
                let r = Relations(dictionary: relations)
                
                usr.relations = r!
                
                self.userProfileThatIsOpen = usr
                dGroup.leave()
                
            } catch let error {
                print("failed to load posts", error.localizedDescription)
            }
        }
        dGroup.wait()
    }
    
    // MARK: User Interface
    
    override var prefersStatusBarHidden: Bool {
        return true
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
        
        numberOfFollowers = userProfileThatIsOpen!.relations!.followers!.count
        followersLabel.text = "followers: " + String(userProfileThatIsOpen!.relations!.followers!.count)
        followingLabel.text = "following: " + String(userProfileThatIsOpen!.relations!.following!.count)

    }
    
    func isUserFollowing() -> Bool {
        let following = UserDefaults.standard.stringArray(forKey: "following") ?? [String]()
        for i in 0 ..< following.count {
            if following[i] == userProfileThatIsOpen!.username! {
                return true
            }
        }
        return false
    }
    
    // MARK: Collection View Delegate Functions
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return userProfileThatIsOpen!.posts!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
    
        // let thisElement = colectionArr[indexPath.item]
        
        let cellIndex = indexPath.item
        let closeFrameSize = bestFrameSize()
        
        cell.contentView.layer.masksToBounds = true
        cell.backgroundColor = UIColor.white

        cell.layer.shadowColor = UIColor.gray.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 1.0
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect:cell.bounds, cornerRadius:cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    
    func bestFrameSize() -> CGFloat {
        let frameHeight = self.view.frame.height
        let frameWidth = self.view.frame.width
        let bestFrameSize = (frameHeight > frameWidth ) ? frameHeight : frameWidth
        return bestFrameSize
    }
}

// MARK: Collection View Delegate Flow Layout

extension ProfileViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let bounds = collectionView.bounds
        let heightVal = self.view.frame.height
        let widthVal = self.view.frame.width
        let cellsize = (heightVal < widthVal) ?  bounds.height/2 : bounds.width/2
        
        return CGSize(width: cellsize - 10   , height:  cellsize - 10  )
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}
