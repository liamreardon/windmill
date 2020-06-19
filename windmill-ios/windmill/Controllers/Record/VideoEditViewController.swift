//
//  VideoEditViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-07.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import Photos
import AVKit
import AVFoundation

protocol StickerDelegate {
    func viewTapped(view: UIView)
    func imageTapped(image: UIImage)
}

class VideoEditViewController: UIViewController, UITabBarControllerDelegate {
    
    // MARK: IVARS

    internal var avPlayer: AVPlayer?
    internal var avPlayerLayer: AVPlayerLayer!
    internal var videoURL: URL!
    internal var vSpinner: UIView?
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var tempImageView: UIImageView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var toolbar: UIToolbar!
    
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
    
    internal var textButton: UIBarButtonItem!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = self
        
        setupPlayer()
        addLoopObserver()
        setupUI()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        removeLoopObserver()
    }
    
    // MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! UploadVideoViewController
        vc.videoURL = sender as? URL
        vc.prevVC = self
    }
    
    // MARK: Setup Player
    
    internal func setupPlayer() {
        avPlayer = AVPlayer()
        avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = view.bounds
        avPlayerLayer.videoGravity = .resizeAspectFill
        videoView.layer.insertSublayer(avPlayerLayer, at: 0)

        let playerItem = AVPlayerItem(url: videoURL as URL)
        avPlayer!.replaceCurrentItem(with: playerItem)

        avPlayer!.play()
    }
    
    // MARK: User Interface
    
    internal func setupUI() {
        // Trash Icon
        let icon = UIImage(systemName: "trash", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let imageView = UIImageView(image: icon)
        deleteView.addSubview(imageView)
        
        // Back Button Icon
        let icon2 = UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let button = UIButton()
        button.frame = CGRect(x:0, y:0, width: 51, height: 31)
        button.setImage(icon2, for: .normal)
        button.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
        let barButton = UIBarButtonItem()
        barButton.customView = button
        self.navigationItem.leftBarButtonItem = barButton
        
        // Next Button Icon
        let button2 = UIButton()
        button2.frame = CGRect(x:0, y:0, width: 70, height: 35)
        button2.setTitle("Next", for: .normal)
        button2.titleLabel?.font =  UIFont(name: "Ubuntu", size: 18)
        button2.layer.backgroundColor = UIColor(rgb: 0x00B894).cgColor
        button2.layer.cornerRadius = 17.0
        button2.addTarget(self, action: #selector(self.nextButtonTapped), for: .touchUpInside)
        let barButton2 = UIBarButtonItem()
        barButton2.customView = button2
        
        // Text Button Icon
        let button3 = UIButton()
        let icon3 = UIImage(systemName: "textbox", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        button3.frame = CGRect(x:0, y:0, width: 51, height: 31)
        button3.setImage(icon3, for: .normal)
        button3.addTarget(self, action: #selector(self.addTextButtonTapped), for: .touchUpInside)
        let barButton3 = UIBarButtonItem()
        barButton3.customView = button3
        textButton = barButton3
        
        // Toolbar Setup
        toolbar.setBackgroundImage(UIImage(),
                                        forToolbarPosition: .any,
                                        barMetrics: .default)
        toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbar.setItems([barButton3, flexibleSpace, barButton2], animated: false)

    }
    
    // MARK: User Interaction
    
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

        textView.autocorrectionType = .no
        textView.isScrollEnabled = false
        textView.delegate = self
        self.tempImageView.addSubview(textView)
        addGestures(view: textView)
        textView.becomeFirstResponder()
    }
    
    @objc internal func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc internal func nextButtonTapped() {
        convertVideo(videoURL: videoURL!)
    }
    
    @objc internal func dismissKeyboard() {
        view.endEditing(true)
        tempImageView.isUserInteractionEnabled = true
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
    
    // MARK: Video Functions
    internal func convertVideo(videoURL: URL) {
        self.showSpinner(onView: self.videoView)
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let myDocumentPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent("temp.mp4").absoluteString
        _ = NSURL(fileURLWithPath: myDocumentPath)
        let documentsDirectory2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
        let filePath = documentsDirectory2.appendingPathComponent("video.mp4")
        deleteFile(filePath: filePath as NSURL)

        if FileManager.default.fileExists(atPath: myDocumentPath) {
            do { try FileManager.default.removeItem(atPath: myDocumentPath)
            } catch let error { print(error) }
        }
        
        let asset = AVURLAsset(url: videoURL as URL)
        let composition = AVMutableComposition.init()
        composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        let clipVideoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

        let transformer = AVMutableVideoCompositionLayerInstruction(assetTrack: clipVideoTrack)

        let videoTransform: CGAffineTransform = clipVideoTrack.preferredTransform

        var videoAssetOrientation_ = UIImage.Orientation.up
       
        var isVideoAssetPortrait_  = false
       
        if videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0 {
            videoAssetOrientation_ = UIImage.Orientation.right
            isVideoAssetPortrait_ = true
        }
        if videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0 {
            videoAssetOrientation_ =  UIImage.Orientation.left
            isVideoAssetPortrait_ = true
        }
        if videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0 {
            videoAssetOrientation_ =  UIImage.Orientation.up
        }
        if videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0 {
            videoAssetOrientation_ = UIImage.Orientation.down;
        }
       
        transformer.setTransform(clipVideoTrack.preferredTransform, at: CMTime.zero)
        transformer.setOpacity(0.0, at: asset.duration)

        var naturalSize: CGSize
        if(isVideoAssetPortrait_){
            naturalSize = CGSize(width: clipVideoTrack.naturalSize.height, height: clipVideoTrack.naturalSize.width)
        } else {
            naturalSize = clipVideoTrack.naturalSize;
        }
       
        var renderWidth: CGFloat!
        var renderHeight: CGFloat!

        renderWidth = naturalSize.width
        renderHeight = naturalSize.height

        let parentlayer = CALayer()
        let videoLayer = CALayer()
        let watermarkLayer = CALayer()

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = CGSize(width: renderWidth, height: renderHeight)
        videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        videoComposition.renderScale = 1.0
       
        watermarkLayer.contents = tempImageView.asImage().cgImage

        parentlayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)
        videoLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)
        watermarkLayer.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: naturalSize)

        parentlayer.addSublayer(videoLayer)
        parentlayer.addSublayer(watermarkLayer)

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayers: [videoLayer], in: parentlayer)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeMakeWithSeconds(60, preferredTimescale: 30))

        instruction.layerInstructions = [transformer]
        videoComposition.instructions = [instruction]

        let exporter = AVAssetExportSession.init(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputFileType = AVFileType.mov
        exporter?.outputURL = filePath
        exporter?.videoComposition = videoComposition

        exporter!.exportAsynchronously(completionHandler: {() -> Void in
            if exporter?.status == .completed {
                let outputURL: URL? = exporter?.outputURL
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL!)
                }) { saved, error in
                    if saved {
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                        let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions).lastObject
                        PHImageManager().requestAVAsset(forVideo: fetchResult!, options: nil, resultHandler: { (avurlAsset, audioMix, dict) in
                            let newObj = avurlAsset as! AVURLAsset
                            DispatchQueue.main.async(execute: {
                                self.performSegue(withIdentifier: "postVideo", sender: newObj.url)
                                self.removeSpinner()
                            })
                        })
                    }
                }
            }
        })
    }
    
    func deleteFile(filePath:NSURL) {
        guard FileManager.default.fileExists(atPath: filePath.path!) else {
            return
        }
        
        do { try FileManager.default.removeItem(atPath: filePath.path!)
        } catch { fatalError("Unable to delete file: \(error)") }
    }
    
    internal func showSpinner(onView: UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        let ai = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.large)
        ai.color = .white
        ai.startAnimating()
        ai.center = spinnerView.center
        
        spinnerView.addSubview(ai)
        onView.addSubview(spinnerView)
        
        vSpinner = spinnerView
    }
    
    internal func removeSpinner() {
        vSpinner?.removeFromSuperview()
        vSpinner = nil
    }
    
    // MARK: Tab Bar Controller Delegate Functions
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabBarIndex = tabBarController.selectedIndex
        if tabBarIndex != 2 {
            navigationController?.popViewController(animated: false)
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

// MARK: Sticker Delegate

extension VideoEditViewController: StickerDelegate {
    
    func viewTapped(view: UIView) {
        view.center = tempImageView.center
        
        self.tempImageView.addSubview(view)
        
        addGestures(view: view)
    }
    
    func imageTapped(image: UIImage) {

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame.size = CGSize(width: 150, height: 150)
        imageView.center = tempImageView.center
        
        self.tempImageView.addSubview(imageView)
        
        addGestures(view: imageView)
    }
    
    
    func addGestures(view: UIView) {
        
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


