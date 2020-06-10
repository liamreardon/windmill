//
//  RecordViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-06.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import AVFoundation
import NextLevel
import ARKit

class RecordViewController: UIViewController {
    
    // MARK: IVARS
    
    internal var previewView: UIView!
    internal var nextLevel: NextLevel?
    internal var tapGestureRecognizer: UITapGestureRecognizer?
    internal var bufferRenderer: NextLevelBufferRenderer?
    internal var isRecording: Bool = false
    internal var videoURL: URL?
    internal var vSpinner: UIView?
    @IBOutlet weak var exitButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!
    
    internal var recordButton: RecordButton = {
        let button = RecordButton(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)))
        return button
    }()
    
    internal var resetButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 50))
        return button
    }()
    
    internal var flipCameraButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 80, height: 50))
        return button
    }()

    internal lazy var videoLongPressGestureRecognizer: UILongPressGestureRecognizer = {
        let videoLongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleVideoLongPressGestureRecognizer(_:)))
        videoLongPressGestureRecognizer.minimumPressDuration = 0
        videoLongPressGestureRecognizer.numberOfTouchesRequired = 1
        videoLongPressGestureRecognizer.allowableMovement = 10.0
        return videoLongPressGestureRecognizer
    }()
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        self.setupCamera()
        self.setupRecordButton()
        self.setupResetButton()
        self.setupFlipCameraButton()
        self.setupBarButtonItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.resetCapture()
        self.stopCamera()
        self.resetButton.isHidden = true
        self.removeSpinner()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.enableUI()
    }
    
    // MARK: Segue
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! VideoEditViewController
        vc.videoURL = sender as? URL
    }
}

// MARK: Camera Setup

extension RecordViewController {
    
    internal func setupCamera() {
        self.nextLevel = NextLevel()
        let screenBounds = UIScreen.main.bounds
        self.previewView = UIView(frame: screenBounds)
        if let nextLevel = self.nextLevel {
            if let previewView = self.previewView {
                
                nextLevel.delegate = self
                nextLevel.videoDelegate = self

                nextLevel.isVideoCustomContextRenderingEnabled = true
                nextLevel.videoStabilizationMode = .off
                nextLevel.frameRate = 60
                
                // video configuration
                nextLevel.videoConfiguration.maximumCaptureDuration = CMTime(seconds: 12.0, preferredTimescale: 600)
                nextLevel.videoConfiguration.bitRate = 15000000
                nextLevel.videoConfiguration.maxKeyFrameInterval = 30
                nextLevel.videoConfiguration.scalingMode = AVVideoScalingModeResizeAspectFill
                nextLevel.videoConfiguration.codec = AVVideoCodecType.hevc

                previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                previewView.backgroundColor = UIColor.black
                nextLevel.previewLayer.frame = previewView.bounds
                previewView.layer.addSublayer(nextLevel.previewLayer)
                self.view.addSubview(previewView)
            }
        }
    }
    
    internal func startCamera() {
        if NextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
            NextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {

            do {
                try self.nextLevel?.start()
            } catch let error {
                print("failed to start camera \(error)")
            }
        } else {
            NextLevel.requestAuthorization(forMediaType: .video) { (mediaType, status) in
                print("NextLevel, authorization updated for media \(mediaType) status \(status)")
                if NextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
                    NextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
                    self.startCamera()
                }
            }
            
            NextLevel.requestAuthorization(forMediaType: AVMediaType.audio) { (mediaType, status) in
                print("NextLevel, authorization updated for media \(mediaType) status \(status)")
                if NextLevel.authorizationStatus(forMediaType: AVMediaType.video) == .authorized &&
                    NextLevel.authorizationStatus(forMediaType: AVMediaType.audio) == .authorized {
                    self.startCamera()
                }
            }
        }
    }
    
    internal func stopCamera() {
        self.nextLevel?.stop()
    }
}

// MARK: Capture

extension RecordViewController {
    
    internal func startCapture() {
        self.nextLevel?.record()
    }
    
    internal func resetCapture() {
        self.recordButton.reset()
        self.nextLevel?.session?.removeAllClips()
        self.resetButton.isHidden = true
    }
    
    internal func endCapture() {
        self.nextLevel?.pause()
    }

}

// MARK: User Interface

extension RecordViewController {
    
    internal func setupRecordButton() {
        var safeAreaBottom: CGFloat = 0.0
        safeAreaBottom = self.view.safeAreaInsets.bottom + 50.0
        let height = self.recordButton.frame.size.height * 0.5
        self.recordButton.center = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.size.height - safeAreaBottom - (height) - 50.0)
        self.recordButton.addGestureRecognizer(self.videoLongPressGestureRecognizer)
        self.view.addSubview(self.recordButton)
    }
    
    internal func setupResetButton() {
        var safeAreaBottom: CGFloat = 0.0
        let height = self.recordButton.frame.size.height * 0.5
        safeAreaBottom = self.view.safeAreaInsets.bottom + 50.0
        let icon = UIImage(systemName: "delete.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 33, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        self.resetButton.setImage(icon, for: .normal)
        self.resetButton.center = CGPoint(x: (self.view.bounds.minX + self.view.bounds.midX) / 2, y: self.view.bounds.size.height - safeAreaBottom - (height) - 50.0)
        self.resetButton.addTarget(self, action: #selector(self.resetButtonTapped), for: .touchUpInside)
        self.resetButton.isHidden = true
        self.view.addSubview(self.resetButton)
    }
    
    internal func setupFlipCameraButton() {
        var safeAreaBottom: CGFloat = 0.0
        let height = self.recordButton.frame.size.height * 0.5
        safeAreaBottom = self.view.safeAreaInsets.bottom + 50.0
        let icon = UIImage(systemName: "camera.rotate", withConfiguration: UIImage.SymbolConfiguration(pointSize: 33, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        self.flipCameraButton.setImage(icon, for: .normal)
        self.flipCameraButton.center = CGPoint(x: (self.view.bounds.midX + self.view.bounds.maxX) / 2, y: self.view.bounds.size.height - safeAreaBottom - (height) - 50.0)
        self.flipCameraButton.addTarget(self, action: #selector(self.flipCameraButtonTapped), for: .touchUpInside)
        self.view.addSubview(self.flipCameraButton)
    }
    
    internal func setupBarButtonItems() {
        let icon = UIImage(systemName: "arrow.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let button = UIButton()
        button.frame = CGRect(x:0, y:0, width: 51, height: 31)
        button.setImage(icon, for: .normal)
        button.addTarget(self, action: #selector(self.nextButtonTapped), for: .touchUpInside)
        let barButton = UIBarButtonItem()
        barButton.customView = button
        self.navigationItem.rightBarButtonItem = barButton
        self.nextButton = self.navigationItem.rightBarButtonItem
        self.nextButton.isEnabled = false
        
        let icon2 = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let button2 = UIButton()
        button2.frame = CGRect(x:0, y:0, width: 51, height: 31)
        button2.setImage(icon2, for: .normal)
        button2.addTarget(self, action: #selector(self.exitButtonTapped), for: .touchUpInside)
        let barButton2 = UIBarButtonItem()
        barButton2.customView = button2
        self.navigationItem.leftBarButtonItem = barButton2
        self.exitButton = self.navigationItem.leftBarButtonItem
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
    
    internal func disableUI() {
        self.exitButton.isEnabled = false
        self.nextButton.isEnabled = false
        self.resetButton.isEnabled = false
        self.flipCameraButton.isEnabled = false
    }
    
    internal func enableUI() {
        self.exitButton.isEnabled = true
        self.nextButton.isEnabled = false
        self.resetButton.isEnabled = true
        self.flipCameraButton.isEnabled = true
    }}

// MARK: Gestures

extension RecordViewController {
    @objc internal func handleVideoLongPressGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.isRecording = true
            self.recordButton.startRecordingAnimation()
            self.startCapture()
            break
        case .changed:
            break
        case .failed:
            fallthrough
        case .cancelled:
            fallthrough
        case .ended:
            self.isRecording = false
            self.recordButton.stopRecordingAnimation()
            self.endCapture()
            fallthrough
        default:
            break
        }
    }
    
    @objc internal func nextButtonTapped() {
        if let session = self.nextLevel?.session {
            self.showSpinner(onView: self.previewView)
            self.disableUI()
            if session.clips.count > 1 {
                session.mergeClips(usingPreset: AVAssetExportPresetHighestQuality, completionHandler: { (url: URL?, error: Error?) in
                    if let url = url {
                        self.performSegue(withIdentifier: "editVideo", sender: url)
                    } else if let _ = error {
                        print("failed to merge clips at the end of capture \(String(describing: error))")
                    }
                })
            } else if let lastClipUrl = session.lastClipUrl {
                self.performSegue(withIdentifier: "editVideo", sender: lastClipUrl)
            } else if session.currentClipHasStarted {
                session.endClip(completionHandler: { (clip, error) in
                    if error == nil {
                        print("end clip")
                    } else {
                        print("Error saving video: \(error?.localizedDescription ?? "")")
                    }
                })
            } else {
                self.removeSpinner()
                self.enableUI()
                let alertController = UIAlertController(title: "Video Failed", message: "Not enough video captured!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @objc internal func exitButtonTapped() {
        self.tabBarController?.selectedIndex = 0
    }
    
    @objc internal func resetButtonTapped() {
        self.nextLevel?.session?.removeLastClip()
        let currentProgress = (self.nextLevel!.session!.totalDuration.seconds / 12.0).clamped(to: 0...1)
        self.recordButton.updateProgress(progress: Float(currentProgress), animated: true)
        if currentProgress == 0 {
            self.resetButton.isHidden = true
        }
        if currentProgress < 3 {
            self.nextButton.isEnabled = false
        }
    }
    
    @objc internal func flipCameraButtonTapped() {
        nextLevel?.flipCaptureDevicePosition()
    }
}

// MARK: - NextLevel Delegate

extension RecordViewController: NextLevelDelegate {
    
    public func nextLevel(_ nextLevel: NextLevel, didUpdateAuthorizationStatus status: NextLevelAuthorizationStatus, forMediaType mediaType: AVMediaType) {
    }
    
    // configuration
    public func nextLevel(_ nextLevel: NextLevel, didUpdateVideoConfiguration videoConfiguration: NextLevelVideoConfiguration) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didUpdateAudioConfiguration audioConfiguration: NextLevelAudioConfiguration) {
    }
    
    // session
    public func nextLevelSessionWillStart(_ nextLevel: NextLevel) {
        #if PROTOTYPE
        TinyConsole.print("📷 will start")
        #endif
    }
    
    public func nextLevelSessionDidStart(_ nextLevel: NextLevel) {
        #if PROTOTYPE
        TinyConsole.print("📷 did start")
        #endif
    }
    
    public func nextLevelSessionDidStop(_ nextLevel: NextLevel) {
    }
    
    // session interruption
    public func nextLevelSessionWasInterrupted(_ nextLevel: NextLevel) {
    }
    
    public func nextLevelSessionInterruptionEnded(_ nextLevel: NextLevel) {
    }
    
    // preview
    public func nextLevelWillStartPreview(_ nextLevel: NextLevel) {
    }
    
    public func nextLevelDidStopPreview(_ nextLevel: NextLevel) {
    }
    
    // mode
    public func nextLevelCaptureModeWillChange(_ nextLevel: NextLevel) {
    }
    
    public func nextLevelCaptureModeDidChange(_ nextLevel: NextLevel) {
    }
    
}

extension RecordViewController: NextLevelVideoDelegate {
    
    // video zoom
    public func nextLevel(_ nextLevel: NextLevel, didUpdateVideoZoomFactor videoZoomFactor: Float) {
    }
    
    // video frame processing
    public func nextLevel(_ nextLevel: NextLevel, willProcessRawVideoSampleBuffer sampleBuffer: CMSampleBuffer, onQueue queue: DispatchQueue) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, willProcessFrame frame: AnyObject, timestamp: TimeInterval, onQueue queue: DispatchQueue) {
    }
    
    // enabled by isCustomContextVideoRenderingEnabled
    public func nextLevel(_ nextLevel: NextLevel, renderToCustomContextWithImageBuffer imageBuffer: CVPixelBuffer, onQueue queue: DispatchQueue) {

    }
    
    // video recording session
    
    public func nextLevel(_ nextLevel: NextLevel, didSetupVideoInSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSetupAudioInSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didStartClipInSession session: NextLevelSession) {

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didCompleteClip clip: NextLevelClip, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didAppendVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
        if self.isRecording {
            let currentProgress = (session.totalDuration.seconds / 12.0).clamped(to: 0...1)
            self.recordButton.updateProgress(progress: Float(currentProgress), animated: true)
            if session.totalDuration.seconds > 3 {
                self.nextButton.isEnabled = true
            }
            if session.totalDuration.seconds > 0 {
                self.resetButton.isHidden = false
            }

        }
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {

    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
        self.endCapture()
    }
    
    // video frame photo
        
    public func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
    }
    
}







