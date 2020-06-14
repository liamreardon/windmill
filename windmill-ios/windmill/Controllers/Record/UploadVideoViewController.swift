//
//  UploadVideoViewController.swift
//  windmill
//
//  Created by Liam  on 2020-06-13.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation

class UploadVideoViewController: UIViewController, UITabBarControllerDelegate {
    
    // MARK: IVARS
    internal var videoURL: URL!
    internal var prevVC: VideoEditViewController!
    
    @IBOutlet weak var videoDescription: UITextField!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var thumbnailView: UIImageView!
    
    let uploadManager = UploadManager()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
        
        if let thumbnailImage = getThumbnailImage(forUrl: videoURL) {
            thumbnailView.image = thumbnailImage
        }
    }
    
    // MARK: User Interface
    
    internal func setupUI() {
        
    }
    
    // MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! UITabBarController
        vc.modalPresentationStyle = .fullScreen
        vc.selectedIndex = 0
        prevVC.removeLoopObserver()
    }
    
    // MARK: User Interaction
    @IBAction func postButtonTapped(_ sender: Any) {
        uploadVideo()
        performSegue(withIdentifier: "postToHome", sender: self)
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
    
    // MARK: API Functions
    
    internal func uploadVideo() {
        uploadManager.uploadVideo(videoURL: videoURL as URL)
    }
    
}
