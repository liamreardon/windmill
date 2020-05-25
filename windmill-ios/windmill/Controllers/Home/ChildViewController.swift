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

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var likeButton: UIButton!
    
    fileprivate var videoURL: URL?
    fileprivate var queuePlayer: AVQueuePlayer?
    fileprivate var playerLayer: AVPlayerLayer?
    fileprivate var playbackLooper: AVPlayerLooper?
    
    var index: Int?
    var isChecked: Bool = false
    public var isPaused: Bool = false
    
    let postManager = PostManager()
    var post: Post?
    
    let userId = KeychainWrapper.standard.string(forKey: "userId")

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let index = self.index {
            label.text = "Page " + String(index)
            promptLabel.isHidden = index != 1
        }
        
        prepareVideo()
        isChecked = didUserLikePost()
        configPostUI()
    
    }
    
    // MARK: User Interactions
    @IBAction func likeButton(_ sender: UIButton) {
        isChecked = !isChecked
        
        if isChecked == true {
            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            postManager.likeRequest(userId: userId!, postId: post!.id!, likedStatus: true) { (data) in
                 print(data)
             }
        } else {
            likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            postManager.likeRequest(userId: userId!, postId: post!.id!, likedStatus: false) { (data) in
                 print(data)
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
    
    func configPostUI() {
        if isChecked {
            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            return
        }
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
    }
    

    
    // MARK: Player Functions
    func prepareVideo() {
        
        let playerItem = AVPlayerItem(url: URL.init(string: post!.url!)!)
        
        self.queuePlayer = AVQueuePlayer(playerItem: playerItem)
        self.playerLayer = AVPlayerLayer(player: self.queuePlayer)
        guard let playerLayer = self.playerLayer else {return}
        guard let queuePlayer = self.queuePlayer else {return}
        self.playbackLooper = AVPlayerLooper.init(player: queuePlayer, templateItem: playerItem)
        
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = CGRect.init(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        view.layer.insertSublayer(playerLayer, at: 0)
        
    }
    
    func play() {
        self.isPaused = false
        self.queuePlayer?.play()
    }
     
    func pause() {
        self.isPaused = true
        self.queuePlayer?.pause()
    }
     
    func stop() {
        self.isPaused = true
        self.queuePlayer?.pause()
        self.queuePlayer?.seek(to: CMTime.init(seconds: 0, preferredTimescale: 1))
    }
     
    func unload() {
        self.isPaused = true
        self.playerLayer?.removeFromSuperlayer()
        self.playerLayer = nil
        self.queuePlayer = nil
        self.playbackLooper = nil
    }
    
          
}
