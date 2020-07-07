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
    
    // IVARS

    @IBOutlet weak var likeBtn: UIImageView!
    @IBOutlet weak var numberOfLikesLabel: UILabel!
    
    @IBOutlet weak var commentButton: UIImageView!
    @IBOutlet weak var numberOfCommentsButton: UILabel!
    
    @IBOutlet weak var shareButton: UIImageView!
    
    @IBOutlet var childView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!

    let previewLayer = CALayer()
    
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
    let likeTapRec = UITapGestureRecognizer()
    let commentTapRec = UITapGestureRecognizer()
    
    let commentViewController = CommentViewController()
    
    var vSpinner: UIView?

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
    
    // MARK: User Interaction

    @objc func likeTapped() {
        isChecked = !isChecked
        
        if isChecked {
            let imageIcon = UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(UIColor(rgb: 0xE71C23), renderingMode: .alwaysOriginal)
            likeBtn.image = imageIcon
            numberOfLikesLabel.text = String(Int(numberOfLikesLabel.text!)! + 1)
            postManager.likeRequest(postUserId: post!.userId!, userId: userId!, postId: post!.id!, likedStatus: true) { (data) in
                // res
            }
        } else {
            let imageIcon = UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
            likeBtn.image = imageIcon
            numberOfLikesLabel.text = String(Int(numberOfLikesLabel.text!)! - 1)
            postManager.likeRequest(postUserId: post!.userId!, userId: userId!, postId: post!.id!, likedStatus: false) { (data) in
                // res
            }
        }
    }
    
    @objc func commentTapped() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "commentViewController") as! CommentViewController
        vc.post = post
        self.present(vc, animated: true, completion: nil)
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
    
    // MARK: User Interface
    
    func initGraphics() {
        if isChecked {
            let imageIcon = UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(UIColor(rgb: 0xE71C23), renderingMode: .alwaysOriginal)
            likeBtn.image = imageIcon
        }
        else {
            let imageIcon = UIImage(systemName: "heart.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
            likeBtn.image = imageIcon
        }
        
        if post!.verified! {
            let fullString = NSMutableAttributedString(string: "@\(post!.username!)")
            let image1Attachment = NSTextAttachment()
            let icon = UIImage(systemName: "checkmark.seal.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))?.withTintColor(UIColor(rgb: 0x1bc9fc), renderingMode: .alwaysOriginal)
            image1Attachment.image = icon
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            usernameLabel.attributedText = fullString
        }
            
        else {
            usernameLabel.text = "@\(post!.username!)"
        }
        
        numberOfLikesLabel.text = String(post!.numlikes!)
        captionLabel.text = post?.caption
        likeTapRec.addTarget(self, action: #selector(ChildViewController.likeTapped))
        commentTapRec.addTarget(self, action: #selector(ChildViewController.commentTapped))
        likeBtn.addGestureRecognizer(likeTapRec)
        commentButton.addGestureRecognizer(commentTapRec)
        likeBtn.isUserInteractionEnabled = true
        commentButton.isUserInteractionEnabled = true
        
        let commentIcon = UIImage(systemName: "bubble.left.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        commentButton.image = commentIcon
        
        let shareIcon = UIImage(systemName: "arrowshape.turn.up.right.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        shareButton.image = shareIcon

    }
    
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        let ai = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.large)
        ai.color = .white
        ai.startAnimating()
        ai.center = spinnerView.center
       
        spinnerView.addSubview(ai)
        onView.addSubview(spinnerView)
        
        vSpinner = spinnerView
        vSpinner?.isUserInteractionEnabled = false
    }
    
    func removeSpinner() {
        vSpinner?.removeFromSuperview()
        vSpinner = nil
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
            
            removeSpinner()
            
            // Switch over status value
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                print("playing")
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
