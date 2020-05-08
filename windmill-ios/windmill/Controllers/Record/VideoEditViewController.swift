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

    let avPlayer = AVPlayer()
    var avPlayerLayer: AVPlayerLayer!

    var videoURL: URL!
    
    let postButton = UIView()

    @IBOutlet weak var videoView: UIView!
    
    let uploadManager = UploadManager()
    
    var screenHeight = UIScreen.main.bounds.size.height
    var screenWidth = UIScreen.main.bounds.size.width
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // MARK - Configure Player
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        videoView.layer.insertSublayer(avPlayerLayer, at: 0)

        view.layoutIfNeeded()

        let playerItem = AVPlayerItem(url: videoURL as URL)
        avPlayer.replaceCurrentItem(with: playerItem)

        avPlayer.play()
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: self.avPlayer.currentItem, queue: .main) { [weak self] _ in
            self?.avPlayer.seek(to: CMTime.zero)
            self?.avPlayer.play()
        }
        
        // MARK - Configure UI
        
        let postVideoButtonRecognizer = UITapGestureRecognizer(target: self, action: #selector(VideoEditViewController.postVideo))
        
        postButton.isUserInteractionEnabled = true
        postButton.addGestureRecognizer(postVideoButtonRecognizer)
        postButton.frame = CGRect(x: 50, y: screenHeight - 200, width: 100, height: 100)
        postButton.center.x = self.view.center.x

        postButton.backgroundColor = UIColor.blue

        videoView.addSubview(postButton)
    }
    
    @objc func postVideo() {
        uploadVideo()
    }
    
    func uploadVideo() {
        uploadManager.uploadVideo(videoURL: videoURL as URL)
    }
}
