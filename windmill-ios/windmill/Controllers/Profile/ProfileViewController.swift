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
import AVFoundation
import SDWebImage

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: IVARS
    
    @IBOutlet weak var displayPicture: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var optionsButton: UIButton!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var currentUserProfile: Bool = true
    var followingUser: User?
    var userProfileThatIsOpen: User?
    var isFollowing: Bool? = false
    var userPosts: [Post] = []
    
    var numberOfFollowers: Int = 0
    var numberOfFollowing: Int = 0
    
    let userManager = UserManager()
    let storageManager = StorageManager()
    let feedManager = FeedManager()
    let uploadManager = UploadManager()
    
    let refreshControl = UIRefreshControl()
    
    var imagePicker: ImagePicker!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        self.imagePicker = ImagePicker(presentationController: self, delegate: self, mediaType: "public.image")
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(refreshCollection), for: .valueChanged)
        
        if currentUserProfile {
            let username = KeychainWrapper.standard.string(forKey: "username")
            getUser(username: username!)
            getUserDetails()
            initGraphics()
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dpTapped))
            displayPicture.isUserInteractionEnabled = true
            displayPicture.addGestureRecognizer(tapGestureRecognizer)
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
            initGraphics()
        }
        else {
            getUser(username: followingUser!.username!)
            initGraphics()
            loadUserData()
        }
        
        userPosts = userProfileThatIsOpen!.posts!
    }
    
    @objc internal func refreshCollection() {
        if currentUserProfile {
            let username = KeychainWrapper.standard.string(forKey: "username")
            getUser(username: username!)
            getUserDetails()
            initGraphics()
        }
        else {
            getUser(username: followingUser!.username!)
            loadUserData()
            initGraphics()
        }
        
        userPosts = userProfileThatIsOpen!.posts!
        
        self.collectionView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    // MARK: User Interaction
    
    @IBAction func followButtonTapped(_ sender: Any) {
        
        if isFollowing! {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

            let unfollowAction = UIAlertAction(title: "Unfollow", style: .destructive) { (action) in
                self.isFollowing = false
                self.followTappedHandler()
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                return
            }

            actionSheet.addAction(unfollowAction)
            actionSheet.addAction(cancelAction)
            
            self.present(actionSheet, animated: true, completion: nil)
        }
        else {
            isFollowing! = !isFollowing!
            followTappedHandler()
        }

    }
    
    @IBAction func optionsButtonTapped(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Options", message: nil, preferredStyle: .actionSheet)

        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { (action) in
            self.signOut()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            return
        }

        actionSheet.addAction(signOutAction)
        actionSheet.addAction(cancelAction)

        self.present(actionSheet, animated: true, completion: nil)
    }
    
    internal func followTappedHandler() {
        let username = KeychainWrapper.standard.string(forKey: "username")
        var following = UserDefaults.standard.stringArray(forKey: "following") ?? [String]()
        if isFollowing! {
            following.append(userProfileThatIsOpen!.username!)
            numberOfFollowers += 1
            userManager.updateUserFollowingStatus(username: username!, followingUsername: followingUser!.username!, followingStatus: true) { (data) in
                    UserDefaults.standard.set(following, forKey: "following")
            }
            
            followButton.backgroundColor = UIColor(rgb: 0xc8d6e5)
            followButton.setTitle("Unfollow -", for: .normal)
            followButton.setTitleColor(UIColor(rgb: 0x576574), for: .normal)
            
        }
        else {
            numberOfFollowers -= 1
            let newFollowing = following.filter {$0 != userProfileThatIsOpen?.username}
            userManager.updateUserFollowingStatus(username: username!, followingUsername: followingUser!.username!, followingStatus: false) { (data) in
                    UserDefaults.standard.set(newFollowing, forKey: "following")
            }
            
            followButton.backgroundColor = UIColor(rgb: 0x576574)
            followButton.setTitle("Follow +", for: .normal)
            followButton.setTitleColor(UIColor(rgb: 0xc8d6e5), for: .normal)
        }
        
        followersLabel.text = "followers: " + String(numberOfFollowers)
    }
    
    internal func signOut() {
        print("signing out...")
        GIDSignIn.sharedInstance()?.signOut()
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "loginMain") as UIViewController
            vc.modalPresentationStyle = .fullScreen
            UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
        }
        
    }
    
    @objc internal func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc internal func dpTapped() {
        self.imagePicker.present(from: view)
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
    
    func initGraphics() {
        displayPicture.layer.borderWidth = 1.6
        displayPicture.layer.masksToBounds = false
        displayPicture.layer.borderColor = UIColor.white.cgColor
        displayPicture.layer.cornerRadius = displayPicture.frame.height / 2
        displayPicture.clipsToBounds = true
        
        let icon3 = UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let button3 = UIButton()
        button3.frame = CGRect(x:0, y:0, width: 51, height: 31)
        button3.setImage(icon3, for: .normal)
        button3.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
        let barButton3 = UIBarButtonItem()
        barButton3.customView = button3
        self.navigationItem.leftBarButtonItem = barButton3
        
        followButton.layer.cornerRadius = 10.0
        
        if isFollowing! {
            followButton.backgroundColor = UIColor(rgb: 0xc8d6e5)
            followButton.setTitle("Unfollow -", for: .normal)
            followButton.setTitleColor(UIColor(rgb: 0x576574), for: .normal)
        }
        else {
            followButton.backgroundColor = UIColor(rgb: 0x576574)
            followButton.setTitle("Follow +", for: .normal)
            followButton.setTitleColor(UIColor(rgb: 0xc8d6e5), for: .normal)
        }
        
        let icon = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        optionsButton.setImage(icon, for: .normal)
        
        if !currentUserProfile {
            optionsButton.isHidden = true
        }
    }

    
    // MARK: Following User Setup
    
    func loadUserData() {
       
        if followingUser?.displaypicture != nil {
            let url = URL(string: followingUser!.displaypicture!)
            displayPicture.sd_imageIndicator = SDWebImageActivityIndicator.white
            displayPicture.sd_setImage(with: url!, placeholderImage: UIImage(named: ""))
        }
        
        usernameLabel.text = followingUser?.username
        isFollowing = isUserFollowing()
        if isFollowing! {
            followButton.setTitle("Unfollow -", for: .normal)
        }
        else {
            followButton.setTitle("Follow +", for: .normal)
        }
        
        numberOfFollowers = userProfileThatIsOpen!.relations!.followers!.count
        followersLabel.text = "followers: " + String(userProfileThatIsOpen!.relations!.followers!.count)
        followingLabel.text = "following: " + String(userProfileThatIsOpen!.relations!.following!.count)
        
        if userProfileThatIsOpen!.verified! {
            
            let fullString = NSMutableAttributedString(string: "@\(followingUser!.username!)")
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = UIImage(named: "check.png")
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            usernameLabel.attributedText = fullString
        }
        
        else {
            usernameLabel.text = "@\(followingUser!.username!)"
        }

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
    
    // MARK: Services
    
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60) , actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }

        return nil
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
    
        let currentElement = userPosts[indexPath.item]
        
        cell.cellImage.sd_imageIndicator = SDWebImageActivityIndicator.white
        cell.cellImage.sd_setImage(with: URL(string: currentElement.thumbnail!), placeholderImage: UIImage(named: ""))
     
        let bounds = collectionView.bounds
        cell.cellImage.frame.size.height = 210
        cell.cellImage.frame.size.width = (bounds.width / 3) - 10
        
        cell.contentView.layer.masksToBounds = true

        cell.layer.backgroundColor = UIColor(rgb: 0x2d3436).cgColor
        cell.layer.masksToBounds = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         // handle tap events
         print("You selected cell #\(indexPath.item)!")
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
        return CGSize(width: (bounds.width / 3) - 10, height: 210)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
}

extension ProfileViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        if image == nil { return }
        self.displayPicture.image = image
        let userId = KeychainWrapper.standard.string(forKey: "userId")
        storageManager.store(image: image!, forKey: userId!+"displayPicture", withStorageType: .fileSystem)
        uploadManager.uploadProfilePicture(image: image!)
    }
    
    func didSelectVideo(url: URL?) {
        
    }
}
