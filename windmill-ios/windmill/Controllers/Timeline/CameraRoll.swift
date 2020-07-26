//
//  CameraRoll.swift
//  windmill
//
//  Created by Liam  on 2020-07-20.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Photos
import UIKit

struct CameraRoll {
    
    func saveToCameraRoll(url: URL, vc: UIViewController) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { saved, error in
            if saved {
                let alertController = UIAlertController(title: "Video was saved to your camera roll.", message: nil, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                vc.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
