//
//  VideoEditViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-07.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import AVFoundation

protocol StickerDelegate {
    func viewTapped(view: UIView)
    func imageTapped(image: UIImage)
}

class VideoEditViewController: UIViewController {
    
    // IVARS

    internal var avPlayer: AVPlayer?
    internal var avPlayerLayer: AVPlayerLayer!
    internal var videoURL: URL!
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var deleteView: UIView!
    
    internal var imageViewToPan: UIImageView?
    internal var textColor: UIColor = UIColor.white
    internal var lastTextViewTransform: CGAffineTransform?
    internal var lastTextViewTransCenter: CGPoint?
    internal var lastTextViewFont:UIFont?
    internal var activeTextView: UITextView?
    
    internal var lastPanPoint: CGPoint?
    
    let uploadManager = UploadManager()
    let postButton = UIView()
    
    internal var screenHeight = UIScreen.main.bounds.size.height
    internal var screenWidth = UIScreen.main.bounds.size.width
    
    internal var textButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 50))
        return button
    }()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        setupAddTextButton()
        addLoopObserver()
        setupUI()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
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

        let playerItem = AVPlayerItem(url: videoURL as URL)
        avPlayer!.replaceCurrentItem(with: playerItem)

        avPlayer!.play()
    }
    
    // MARK: User Interface
    
    internal func setupAddTextButton() {
        var safeAreaBottom: CGFloat = 0.0
        let height = 100 * 0.5
        safeAreaBottom = self.view.safeAreaInsets.bottom + 50.0
        let icon = UIImage(systemName: "textbox", withConfiguration: UIImage.SymbolConfiguration(pointSize: 33, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        textButton.setImage(icon, for: .normal)
        textButton.center = CGPoint(x: (self.view.bounds.midX + self.view.bounds.maxX) / 2, y: self.view.bounds.size.height - safeAreaBottom - (CGFloat(height)) - 50.0)
        textButton.addTarget(self, action: #selector(self.addTextButtonTapped), for: .touchUpInside)
        view.addSubview(self.textButton)
    }
    
    internal func setupUI() {
        let icon = UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let imageView = UIImageView(image: icon)
        deleteView.addSubview(imageView)
    }
    
    // MARK: User Interaction
    
    @objc internal func postVideo() {
        uploadVideo()
        let storyboard = UIStoryboard(name: "WindmillMain", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "tabBarController") as UIViewController
        vc.modalPresentationStyle = .fullScreen
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
    
    @objc internal func addTextButtonTapped() {
        let textView = UITextView(frame: CGRect(x: 0, y: tempImageView.center.y,
                                                width: UIScreen.main.bounds.width, height: 30))
        
        textView.textAlignment = .center
        textView.font = UIFont(name: "Helvetica", size: 40)
        textView.textColor = textColor
        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOffset = CGSize(width: 1.0, height: 0.0)
        textView.layer.shadowOpacity = 0.2
        textView.layer.shadowRadius = 1.0
        textView.layer.backgroundColor = UIColor.clear.cgColor
        //
        textView.autocorrectionType = .no
        textView.isScrollEnabled = false
        textView.delegate = self
        self.tempImageView.addSubview(textView)
        addGestures(view: textView)
        textView.becomeFirstResponder()
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
        tempImageView.isUserInteractionEnabled = true
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

// MARK: Text View Delegate

extension VideoEditViewController: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        let rotation = atan2(textView.transform.b, textView.transform.a)
        if rotation == 0 {
            let oldFrame = textView.frame
            let sizeToFit = textView.sizeThatFits(CGSize(width: oldFrame.width, height:CGFloat.greatestFiniteMagnitude))
            textView.frame.size = CGSize(width: oldFrame.width, height: sizeToFit.height)
        }
    }
    public func textViewDidBeginEditing(_ textView: UITextView) {
        lastTextViewTransform = textView.transform
        lastTextViewTransCenter = textView.center
        lastTextViewFont = textView.font!
        activeTextView = textView
        textView.superview?.bringSubviewToFront(textView)
        textView.font = UIFont(name: "Helvetica", size: 40)
        UIView.animate(withDuration: 0.3,
                       animations: {
                        textView.transform = CGAffineTransform.identity
                        textView.center = CGPoint(x: UIScreen.main.bounds.width / 2, y: 100)
        }, completion: nil)
        
    }
    
    public func textViewDidEndEditing(_ textView: UITextView) {
        guard lastTextViewTransform != nil && lastTextViewTransCenter != nil && lastTextViewFont != nil
            else {
                return
        }
        activeTextView = nil
        textView.font = self.lastTextViewFont!
        UIView.animate(withDuration: 0.3,
                       animations: {
                        textView.transform = self.lastTextViewTransform!
                        textView.center = self.lastTextViewTransCenter!
        }, completion: nil)
    }
}

extension VideoEditViewController: StickerDelegate {
    
    func viewTapped(view: UIView) {
        view.center = tempImageView.center
        
        self.tempImageView.addSubview(view)
        //Gestures
        addGestures(view: view)
    }
    
    func imageTapped(image: UIImage) {

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame.size = CGSize(width: 150, height: 150)
        imageView.center = tempImageView.center
        
        self.tempImageView.addSubview(imageView)
        //Gestures
        addGestures(view: imageView)
    }
    
    
    func addGestures(view: UIView) {
        //Gestures
        view.isUserInteractionEnabled = true
        
        let panGesture = UIPanGestureRecognizer(target: self,
                                                action: #selector(VideoEditViewController.panGesture))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self,
                                                    action: #selector(VideoEditViewController.pinchGesture))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self,
                                                                    action:#selector(VideoEditViewController.rotationGesture) )
        rotationGestureRecognizer.delegate = self
        view.addGestureRecognizer(rotationGestureRecognizer)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(VideoEditViewController.tapGesture))
        view.addGestureRecognizer(tapGesture)
        
    }
}
