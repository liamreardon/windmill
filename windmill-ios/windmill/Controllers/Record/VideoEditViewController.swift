//
//  VideoEditViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-07.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import AVFoundation

class VideoEditViewController: UIViewController {
    
    // IVARS

    var avPlayer: AVPlayer?
    var avPlayerLayer: AVPlayerLayer!

    var videoURL: URL!
    
    let postButton = UIView()

    @IBOutlet weak var videoView: UIView!
    
    let uploadManager = UploadManager()
    
    var screenHeight = UIScreen.main.bounds.size.height
    var screenWidth = UIScreen.main.bounds.size.width
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        setupUI()
        addLoopObserver()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeLoopObserver()
    }
    
    // MARK: Setup Player
    
    internal func setupPlayer() {
        avPlayer = AVPlayer()
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        videoView.layer.insertSublayer(avPlayerLayer, at: 0)

        view.layoutIfNeeded()

        let playerItem = AVPlayerItem(url: videoURL as URL)
        avPlayer!.replaceCurrentItem(with: playerItem)

        avPlayer!.play()
    }
    
    // MARK: User Interface
    
    internal func setupUI() {
        let postVideoButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(VideoEditViewController.postVideo))
        
        postButton.isUserInteractionEnabled = true
        postButton.addGestureRecognizer(postVideoButtonRecognizer)
        postButton.frame = CGRect(x: 50, y: screenHeight - 200, width: 100, height: 100)
        postButton.center.x = self.view.center.x

        postButton.backgroundColor = UIColor.blue

        videoView.addSubview(postButton)
    }
    
    // MARK: User Interaction
    
    @objc internal func postVideo() {
        uploadVideo()
        let storyboard = UIStoryboard(name: "WindmillMain", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "tabBarController") as UIViewController
        vc.modalPresentationStyle = .fullScreen
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
    
    // MARK: API Functions
    
    internal func uploadVideo() {
        uploadManager.uploadVideo(videoURL: videoURL as URL)
    }
    
    // MARK: Observers
    
    internal func addLoopObserver() {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.avPlayer!.currentItem, queue: .main) { [weak self] _ in
            self?.avPlayer!.seek(to: CMTime.zero)
            self?.avPlayer!.play()
        }
    }
    
    internal func removeLoopObserver() {
        NotificationCenter.default.removeObserver(self)
        if avPlayer != nil {
            avPlayer?.replaceCurrentItem(with: nil)
            avPlayer = nil
        }
    }
}
