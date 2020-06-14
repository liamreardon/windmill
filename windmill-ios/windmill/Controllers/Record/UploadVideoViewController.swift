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

class UploadVideoViewController: UIViewController, UITabBarControllerDelegate, UITextViewDelegate {
    
    // MARK: IVARS
    internal var videoURL: URL!
    internal var prevVC: VideoEditViewController!
    
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var thumbnailView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    
    let uploadManager = UploadManager()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
        textView.delegate = self
        
        if let thumbnailImage = getThumbnailImage(forUrl: videoURL) {
            thumbnailView.image = thumbnailImage
        }
        
        setupUI()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    // MARK: User Interface
    
    internal func setupUI() {
        textView.text = "talk about your video (optional)"
        textView.textColor = UIColor.lightGray
        
        postButton.layer.cornerRadius = 20.0
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
    
    @objc internal func dismissKeyboard() {
        view.endEditing(true)
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
        if textView.text == "talk about your video (optional)" {
            uploadManager.uploadVideo(videoURL: videoURL as URL, caption: "nil")
        }
        else {
            uploadManager.uploadVideo(videoURL: videoURL as URL, caption: textView.text!)
        }
        
    }
    
    // MARK: Text View Delegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "talk about your video (optional)"
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }}
