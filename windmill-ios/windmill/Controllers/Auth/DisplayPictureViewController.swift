//
//  DisplayPictureViewController.swift
//  windmill
//
//  Created by Liam  on 2020-06-25.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation

import UIKit
import SwiftKeychainWrapper
import Pastel

class DisplayPictureViewController: UIViewController {
    
    // MARK: IVARS
        
    let authManager = AuthManager()
    let uploadManager = UploadManager()
    let storageManager = StorageManager()
    var imagePicker: ImagePicker!
    var selectedImage: Bool = false
    
    @IBOutlet weak var selectImageButton: UIButton!
    @IBOutlet weak var saveImageButton: UIButton!
    @IBOutlet weak var displayPictureImageView: UIImageView!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePicker = ImagePicker(presentationController: self, delegate: self, mediaType: "public.image")
        setupUI()
    }
    
    // MARK: User Interaction
    
    @IBAction func uploadImageTapped(_ sender: UIButton) {
        self.imagePicker.present(from: sender)
    }
    
    @IBAction func dismissUploadTapped(_ sender: Any) {
        self.goToHome()
    }
    
    @IBAction func saveDisplayPicture(_ sender: Any) {
        let userId = KeychainWrapper.standard.string(forKey: "userId")
        self.storageManager.store(image: displayPictureImageView.image!, forKey: userId!+"displayPicture", withStorageType: .fileSystem)
        uploadManager.uploadProfilePicture(image: displayPictureImageView.image!)
        self.goToHome()
        
    }
    
    // MARK: User Interface
    func setupUI() {
        let pastelView = PastelView(frame: view.bounds)
        pastelView.startPastelPoint = .bottomLeft
        pastelView.endPastelPoint = .topRight
        pastelView.setColors([UIColor(red: 90/255, green: 120/255, blue: 127/255, alpha: 1.0),
                              UIColor(red: 58/255, green: 255/255, blue: 217/255, alpha: 1.0),
                              UIColor(red: 156/255, green: 39/255, blue: 176/255, alpha: 1.0),
                              UIColor(red: 255/255, green: 64/255, blue: 129/255, alpha: 1.0),
                              UIColor(red: 123/255, green: 31/255, blue: 162/255, alpha: 1.0),
                              UIColor(red: 32/255, green: 76/255, blue: 255/255, alpha: 1.0),
                              UIColor(red: 32/255, green: 158/255, blue: 255/255, alpha: 1.0)])
        pastelView.startAnimation()
        pastelView.animationDuration = 2.0
        view.insertSubview(pastelView, at: 0)
        
        selectImageButton.layer.cornerRadius = 20.0
        saveImageButton.layer.cornerRadius = 20.0
        
        displayPictureImageView.layer.borderWidth = 3.0
        displayPictureImageView.layer.masksToBounds = false
        displayPictureImageView.layer.borderColor = UIColor.white.cgColor
        displayPictureImageView.layer.cornerRadius = displayPictureImageView.frame.height / 2
        displayPictureImageView.clipsToBounds = true
        
        saveImageButton.isEnabled = false
    }
    
    
    // MARK: Segue
    
    func goToHome() {
        let storyboard = UIStoryboard(name: "WindmillMain", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "tabBarController") as UIViewController
        vc.modalPresentationStyle = .fullScreen
        UIApplication.topViewController()?.present(vc, animated: true, completion: nil)
    }
    
}

extension DisplayPictureViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        if image == nil { return }
        displayPictureImageView.image = image
        saveImageButton.isEnabled = true
        selectedImage = true
    }
    
    func didSelectVideo(url: URL?) {
        
    }
    
    
}
