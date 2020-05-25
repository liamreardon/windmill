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

class ChildViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    fileprivate var videoURL: URL?
    fileprivate var queuePlayer: AVQueuePlayer?
    fileprivate var playerLayer: AVPlayerLayer?
    fileprivate var playbackLooper: AVPlayerLooper?
    var index: Int?
    var url: String?
    public var isPaused: Bool = false

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
    
    }

    // MARK: Player Functions
    
    func prepareVideo() {
        
        let playerItem = AVPlayerItem(url: URL.init(string: url!)!)
        
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
