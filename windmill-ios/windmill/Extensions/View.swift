//
//  View.swift
//  windmill
//
//  Created by Liam  on 2020-06-13.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    func toImage() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: false)
        let snapshotImageFromMyView = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return snapshotImageFromMyView!
    }
    
    @objc func toImageView() -> UIImageView {
        let tempImageView = UIImageView()
        tempImageView.image = toImage()
        tempImageView.frame = frame
        tempImageView.contentMode = .scaleAspectFit
        return tempImageView
    }
}


extension UIViewController {

    func addObserverForNotification(_ notificationName: Notification.Name, actionBlock: @escaping (Notification) -> Void) {
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: OperationQueue.main, using: actionBlock)
    }

    func removeObserver(_ observer: AnyObject, notificationName: Notification.Name) {
        NotificationCenter.default.removeObserver(observer, name: notificationName, object: nil)
    }

    typealias KeyboardHeightClosure = (CGFloat) -> ()

    func removeKeyboardObserver() {
        removeObserver(self, notificationName: UIResponder.keyboardWillChangeFrameNotification)
    }

    func addKeyboardChangeFrameObserver(willShow willShowClosure: KeyboardHeightClosure?,
                                        willHide willHideClosure: KeyboardHeightClosure?) {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil, queue: OperationQueue.main, using: { [weak self](notification) in
                                                if let userInfo = notification.userInfo,
                                                    let frame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
                                                    let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
                                                    let c = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
                                                    let kFrame = self?.view.convert(frame, from: nil),
                                                    let kBounds = self?.view.bounds {

                                                    let animationType = UIView.AnimationOptions(rawValue: c)
                                                    let kHeight = kFrame.size.height
                                                    UIView.animate(withDuration: duration, delay: 0, options: animationType, animations: {
                                                        if kBounds.intersects(kFrame) { // keyboard will be shown
                                                            willShowClosure?(kHeight)
                                                        } else { // keyboard will be hidden
                                                            willHideClosure?(kHeight)
                                                        }
                                                    }, completion: nil)
                                                } else {
                                                    print("Invalid conditions for UIKeyboardWillChangeFrameNotification")
                                                }
        })
    }
}

