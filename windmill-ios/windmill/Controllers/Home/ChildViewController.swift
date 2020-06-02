//
//  ChildViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import SwiftKeychainWrapper

class ChildViewController: UIViewController {

    @IBOutlet weak var likeBtn: UIImageView!
    @IBOutlet var childView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var verifiedIcon: UIImageView!
    @IBOutlet weak var numberOfLikesLabel: UILabel!
    let previewLayer = CALayer()
    
    var thumbnail: UIImage?
    
    fileprivate var videoURL: URL?
    fileprivate var queuePlayer: AVQueuePlayer!
    fileprivate var playerLayer: AVPlayerLayer!
    fileprivate var playbackLooper: AVPlayerLooper!
    fileprivate var playerItemContext = 0
    
    var index: Int?
    var isChecked: Bool = false
    public var isPaused: Bool = false
    
    let postManager = PostManager()
    var post: Post?
    
    let userId = KeychainWrapper.standard.string(forKey: "userId")
    let tapRec = UITapGestureRecognizer()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareVideo()
        isChecked = didUserLikePost()
        showSpinner(onView: childView)
        initGraphics()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    
    // MARK: User Interactions
    @IBAction func likeButton(_ sender: UIButton) {

        
    }
    
    @objc func likeTapped() {
        isChecked = !isChecked
        
        if isChecked {
            let imageIcon = UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))?.withTintColor(UIColor(rgb: 0xE71C23), renderingMode: .alwaysOriginal)
            likeBtn.image = imageIcon
            numberOfLikesLabel.text = String(Int(numberOfLikesLabel.text!)! + 1)
            postManager.likeRequest(postUserId: post!.userId!, userId: userId!, postId: post!.id!, likedStatus: true) { (data) in
                // res
            }
        } else {
            let imageIcon = UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
            likeBtn.image = imageIcon
            numberOfLikesLabel.text = String(Int(numberOfLikesLabel.text!)! - 1)
            postManager.likeRequest(postUserId: post!.userId!, userId: userId!, postId: post!.id!, likedStatus: false) { (data) in
                // res
            }
        }
    }

    
    // MARK: Post Data
    func didUserLikePost() -> Bool {

        for i in 0 ..< post!.likers!.count {
            if post!.likers![i] == userId {
                return true
            }
        }
        return false
    }
    
    // MARK: UI
    func initGraphics() {
        if isChecked {
            let imageIcon = UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))?.withTintColor(UIColor(rgb: 0xE71C23), renderingMode: .alwaysOriginal)
            likeBtn.image = imageIcon
        }
        else {
            let imageIcon = UIImage(systemName: "heart", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
            likeBtn.image = imageIcon
        }

        if !post!.verified! {
            verifiedIcon.image = nil
        }
        
        numberOfLikesLabel.text = String(post!.numlikes!)
        captionLabel.text = post?.caption
        usernameLabel.text = "@\(post!.username!)"
        tapRec.addTarget(self, action: #selector(ChildViewController.likeTapped))
        likeBtn.addGestureRecognizer(tapRec)
        likeBtn.isUserInteractionEnabled = true

    }
    
    
    
    
    
    func displayThumbnail() {
        previewLayer.frame = view.bounds
        previewLayer.contents = thumbnail
        view.layer.addSublayer(previewLayer)
    }
    
    func removeThumbnail() {
        previewLayer.removeFromSuperlayer()
    }
    

    // MARK: Player Functions
    func prepareVideo() {
        let playerItem = AVPlayerItem(url: URL.init(string: post!.url!)!)
        playerItem.addObserver(self,
                               forKeyPath: #keyPath(AVPlayerItem.status),
                               options: [.old, .new],
                               context: &playerItemContext)
        
        queuePlayer = AVQueuePlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: queuePlayer)
        guard let playerLayer = playerLayer else {return}
        guard let queuePlayer = queuePlayer else {return}
        playbackLooper = AVPlayerLooper.init(player: queuePlayer, templateItem: playerItem)
        
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = CGRect.init(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        
        view.layer.insertSublayer(playerLayer, at: 0)
        
    }
    
    func play() {
        isPaused = false
        queuePlayer?.play()
    }
     
    func pause() {
        isPaused = true
        queuePlayer?.pause()
    }
     
    func stop() {
        isPaused = true
        queuePlayer?.pause()
        queuePlayer?.seek(to: CMTime.init(seconds: 0, preferredTimescale: 1))
    }
     
    func unload() {
        isPaused = true
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        queuePlayer = nil
        playbackLooper = nil
    }
    
    
    // MARK: Observers
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {

        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over status value
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                print("playing")
                removeSpinner()
            case .failed:
                // Player item failed. See error.
                print("failed")
            case .unknown:
                // Player item is not yet ready.
                print("unknown")
            @unknown default:
                print("player default")
            }
            
        }
    }
    
          
}
