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

class RecordViewController: UIViewController {
    
    // MARK: IVARS
    
    internal var previewView: UIView!
    internal var nextLevel: NextLevel?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        self.setupCamera()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.startCamera()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopCamera()
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

                nextLevel.videoConfiguration.maximumCaptureDuration = CMTimeMakeWithSeconds(5, preferredTimescale: 600)
                nextLevel.audioConfiguration.bitRate = 44000
            
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

// MARK: User Interface

extension RecordViewController {
    
    internal func setupRecordButton() {
        
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
//        if let frame = self._bufferRenderer?.videoBufferOutput {
//            nextLevel.videoCustomContextImageBuffer = frame
//        }
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
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didAppendAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didAppendVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
//        let currentProgress = (session.totalDuration.seconds / 12.0).clamped(to: 0...1)
//        self._recordButton.updateProgress(progress: Float(currentProgress), animated: true)
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipVideoPixelBuffer pixelBuffer: CVPixelBuffer, timestamp: TimeInterval, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipVideoSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didSkipAudioSampleBuffer sampleBuffer: CMSampleBuffer, inSession session: NextLevelSession) {
    }
    
    public func nextLevel(_ nextLevel: NextLevel, didCompleteSession session: NextLevelSession) {
//        self.endCapture()
    }
    
    // video frame photo
        
    public func nextLevel(_ nextLevel: NextLevel, didCompletePhotoCaptureFromVideoFrame photoDict: [String : Any]?) {
//        if let dictionary = photoDict,
//            let photoData = dictionary[NextLevelPhotoJPEGKey] as? Data,
//            let photoImage = UIImage(data: photoData) {
//            self.savePhoto(photoImage: photoImage)
//        }
    }
    
}
