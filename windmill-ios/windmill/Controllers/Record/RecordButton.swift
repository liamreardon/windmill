//
//  RecordButton.swift
//  windmill
//
//  Created by Liam  on 2020-06-07.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import Foundation
import RPCircularProgress

public class RecordButton: UIView {
    
    internal lazy var recordIndicatorProgressBackground: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    internal lazy var recordIndicatorProgress: RPCircularProgress = {
        let indicatorProgress = RPCircularProgress()
        indicatorProgress.roundedCorners = false
        indicatorProgress.thicknessRatio = 1
        indicatorProgress.trackTintColor = UIColor(white: 1, alpha: 0.5)
        indicatorProgress.progressTintColor = UIColor.red
        indicatorProgress.isUserInteractionEnabled = false
        return indicatorProgress
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        self.backgroundColor = .clear
        
        self.recordIndicatorProgressBackground.isUserInteractionEnabled = false
        self.recordIndicatorProgressBackground.frame = self.bounds.insetBy(dx: 10.0, dy: 10.0)
        self.recordIndicatorProgressBackground.layer.cornerRadius = self.recordIndicatorProgressBackground.frame.size.height * 0.5
        self.recordIndicatorProgressBackground.layer.borderWidth = 2.0
        self.recordIndicatorProgressBackground.layer.borderColor = UIColor.white.cgColor
        
        self.recordIndicatorProgressBackground.center = self.center
        self.addSubview(self.recordIndicatorProgressBackground)
        
        self.recordIndicatorProgress.frame = self.recordIndicatorProgressBackground.bounds
        self.recordIndicatorProgress.center = self.center
        self.addSubview(self.recordIndicatorProgress)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}

extension RecordButton {
    
    public func startRecordingAnimation() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseInOut, animations: {
            self.recordIndicatorProgress.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            self.recordIndicatorProgressBackground.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (completed: Bool) in
        }
    }
    
    public func stopRecordingAnimation() {
        UIView.animate(withDuration: 0.15, delay: 0, options: .curveEaseOut, animations: {
            self.recordIndicatorProgress.transform = .identity
            self.recordIndicatorProgressBackground.transform = .identity
        }) { (completed: Bool) in
        }
    }
    
    public func updateProgress(progress: Float, animated: Bool) {
        self.recordIndicatorProgress.updateProgress(CGFloat(progress), animated: animated, completion: nil)
    }
    
    public func reset() {
        self.recordIndicatorProgress.transform = .identity
        self.recordIndicatorProgress.updateProgress(0)
    }
    
}
