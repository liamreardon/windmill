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
    var otherUser: User?
    var userProfileThatIsOpen: User?
    var isFollowing: Bool? = false
    var userPosts: [Post] = []
    
    var fromSearch: Bool = false
    var fromActivity: Bool = false
    
    var passedUsername: String?
    
    var indexTapped: Int = 0
    
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
        
        if currentUserProfile {
            followButton.isHidden = true
        }
        
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
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dpTapped))
        displayPicture.isUserInteractionEnabled = true
        displayPicture.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if currentUserProfile {
            followButton.isHidden = true
            let username = KeychainWrapper.standard.string(forKey: "username")
            getUser(username: username!)
        }
        else {
            followButton.isHidden = false
            if fromSearch {
                getUser(username: otherUser!.username!)
            }
            else if fromActivity {
                getUser(username: passedUsername!)
            }
        }
        
        if fromSearch {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        else if fromActivity {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        else {
            navigationController?.setNavigationBarHidden(true, animated: true)
        }

    }
    
    override func viewDidAppear(_ animated: Bool) {

    }
    
    @objc internal func refreshCollection() {
        if currentUserProfile {
            let username = KeychainWrapper.standard.string(forKey: "username")
            getUser(username: username!)
            getUserDetails()
            initGraphics()
        }
        else {
            getUser(username: otherUser!.username!)
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
            userManager.updateUserFollowingStatus(username: username!, followingUsername: otherUser!.username!, followingStatus: true) { (data) in
                    UserDefaults.standard.set(following, forKey: "following")
            }
            
            let fullString = NSMutableAttributedString(string: "Following ", attributes: [NSAttributedString.Key.foregroundColor : UIColor.black])
            let image1Attachment = NSTextAttachment()
            let icon = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))?.withTintColor(.black, renderingMode: .alwaysOriginal)
            image1Attachment.image = icon
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            followButton.backgroundColor = .white
            followButton.setAttributedTitle(fullString, for: .normal)
            
        }
        else {
            numberOfFollowers -= 1
            let newFollowing = following.filter {$0 != userProfileThatIsOpen?.username}
            userManager.updateUserFollowingStatus(username: username!, followingUsername: otherUser!.username!, followingStatus: false) { (data) in
                    UserDefaults.standard.set(newFollowing, forKey: "following")
            }
            
            let fullString = NSMutableAttributedString(string: "Follow ", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
            let image1Attachment = NSTextAttachment()
            let icon = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
            image1Attachment.image = icon
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            let color = UIColor(rgb: 0x576574).withAlphaComponent(0.5)
            followButton.backgroundColor = color
            followButton.setAttributedTitle(fullString, for: .normal)
        }
        
        followersLabel.text = "followers: " + String(numberOfFollowers)
    }
    
    internal func signOut() {
        print("signing out...")
        GIDSignIn.sharedInstance()?.signOut()
        let userId = KeychainWrapper.standard.string(forKey: "userId")
        storageManager.removeImage(forKey: userId!+"displayPicture", inStorageType: .fileSystem)
        KeychainWrapper.standard.removeObject(forKey: "token")
        KeychainWrapper.standard.removeObject(forKey: "username")
        KeychainWrapper.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "followers")
        UserDefaults.standard.removeObject(forKey: "following")
        UserDefaults.standard.removeObject(forKey: "numFollowers")
        UserDefaults.standard.removeObject(forKey: "numFollowing")
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
            let icon = UIImage(systemName: "checkmark.seal.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))?.withTintColor(UIColor(rgb: 0x1bc9fc), renderingMode: .alwaysOriginal)
            image1Attachment.image = icon
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
                self.userPosts = self.userProfileThatIsOpen!.posts!
                
                DispatchQueue.main.async {
                    if self.currentUserProfile {
                        self.getUserDetails()
                        self.initGraphics()
                        self.getDisplayPicture()
                    }
                    else {
                        self.loadUserData()
                        self.initGraphics()
                    }

                    self.collectionView.reloadData()
                }

        
            } catch let error {
                print("failed to load posts", error.localizedDescription)
            }
        }
    }
    
    // MARK: User Interface
    
    func initGraphics() {
        displayPicture.layer.borderWidth = 1.6
        displayPicture.layer.masksToBounds = false
        displayPicture.layer.borderColor = UIColor.white.cgColor
        displayPicture.layer.cornerRadius = displayPicture.frame.height / 2
        displayPicture.clipsToBounds = true
        
        let icon = UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let button = UIButton()
        button.frame = CGRect(x:0, y:0, width: 51, height: 31)
        button.setImage(icon, for: .normal)
        button.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
        let barButton = UIBarButtonItem()
        barButton.customView = button
        self.navigationItem.leftBarButtonItem = barButton
        
        followButton.layer.cornerRadius = 10.0
        
        if isFollowing! {
            let fullString = NSMutableAttributedString(string: "Following ", attributes: [NSAttributedString.Key.foregroundColor : UIColor.black])
            let image1Attachment = NSTextAttachment()
            let icon = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))?.withTintColor(.black, renderingMode: .alwaysOriginal)
            image1Attachment.image = icon
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            followButton.backgroundColor = .white
            followButton.setAttributedTitle(fullString, for: .normal)
        }
        else {
            let fullString = NSMutableAttributedString(string: "Follow ", attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
            let image1Attachment = NSTextAttachment()
            let icon = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
            image1Attachment.image = icon
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            let color = UIColor(rgb: 0x576574).withAlphaComponent(0.5)
            followButton.backgroundColor = color
            followButton.setAttributedTitle(fullString, for: .normal)
        }
        
        let icon2 = UIImage(systemName: "ellipsis", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        optionsButton.setImage(icon2, for: .normal)
        
        if !currentUserProfile {
            optionsButton.isHidden = true
        }
    }

    // MARK: Following User Setup
    
    func loadUserData() {
       
        if userProfileThatIsOpen?.displaypicture != nil {
            if let url = URL(string: userProfileThatIsOpen!.displaypicture!) {
                displayPicture.sd_imageIndicator = SDWebImageActivityIndicator.white
                displayPicture.sd_setImage(with: url, placeholderImage: UIImage(named: ""))
            }
        }
        
        usernameLabel.text = userProfileThatIsOpen?.username
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
            
            let fullString = NSMutableAttributedString(string: "@\(userProfileThatIsOpen!.username!)")
            let image1Attachment = NSTextAttachment()
            let icon = UIImage(systemName: "checkmark.seal.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))?.withTintColor(UIColor(rgb: 0x1da1f2), renderingMode: .alwaysOriginal)
            image1Attachment.image = icon
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            usernameLabel.attributedText = fullString
            
        }
        
        else {
            usernameLabel.text = "@\(userProfileThatIsOpen!.username!)"
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
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! TimelineViewController
        vc.modalPresentationStyle = .fullScreen
        vc.profileTapIndex = indexTapped
        vc.currentUserProfile = currentUserProfile
        vc.currentUser = userProfileThatIsOpen
    }
    
    // MARK: Collection View Delegate Functions
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if userProfileThatIsOpen == nil {
            return 0
        }
        return userProfileThatIsOpen!.posts!.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
    
        let currentElement = userPosts[indexPath.item]
        
        cell.cellImage.sd_imageIndicator = SDWebImageActivityIndicator.white
        cell.cellImage.sd_setImage(with: URL(string: currentElement.thumbnail!), placeholderImage: UIImage(named: ""))
     
        let bounds = collectionView.bounds
        cell.cellImage.frame.size.height = 210
        cell.cellImage.frame.size.width = (bounds.width / 3) - 5
        
        cell.contentView.layer.masksToBounds = true

        cell.layer.backgroundColor = UIColor(rgb: 0x2d3436).cgColor
        cell.layer.masksToBounds = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        indexTapped = indexPath.item
        performSegue(withIdentifier: "profileToTimeline", sender: self)
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
        return CGSize(width: (bounds.width / 3) - 5, height: 210)
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
