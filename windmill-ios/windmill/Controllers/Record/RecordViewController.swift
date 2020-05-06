//
//  RecordViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-06.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

class RecordViewController: UIViewController {
    
    var videoPicker: VideoPicker!
    @IBOutlet weak var recordView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.videoPicker = VideoPicker(presentationController: self, delegate: self)
        
        self.videoPicker.present(from: recordView)
        
    }
    
    
}

extension RecordViewController: VideoPickerDelegate {
    func didSelect(url: URL?) {
        // do stuff with video
    }
}
