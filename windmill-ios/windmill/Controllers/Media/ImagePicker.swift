//
//  ImagePicker.swift
//  windmill
//
//  Created by Liam  on 2020-04-28.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit

public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?)
    func didSelectVideo(url: URL?)
}

open class ImagePicker: NSObject {

    public let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?
    private var mediaType: String!

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate, mediaType: String) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = true
        self.pickerController.mediaTypes = [mediaType]
        
        self.mediaType = mediaType
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }

    public func present(from sourceView: UIView) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if mediaType == "public.image" {
            if let action = self.action(for: .camera, title: "Take photo") {
                alertController.addAction(action)
            }
            
            if let action = self.action(for: .photoLibrary, title: "Photo library") {
                alertController.addAction(action)
            }
        }
        else {
            if let action = self.action(for: .photoLibrary, title: "Photo library") {
                alertController.addAction(action)
            }
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        self.presentationController?.present(alertController, animated: true)
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(image: image)
        
    }
    
    private func pickerController(_ controller: UIImagePickerController, didSelectVideo url: URL?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelectVideo(url: url)
        
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if mediaType == "public.image" {
            self.pickerController(picker, didSelect: nil)
        }
        else {
            self.pickerController(picker, didSelectVideo: nil)
        }
        
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if mediaType == "public.image" {
            guard let image = info[.editedImage] as? UIImage else {
                return self.pickerController(picker, didSelect: nil)
            }
            self.pickerController(picker, didSelect: image)
        }
        else {
            guard let video = info[.mediaURL] as? URL else {
                return self.pickerController(picker, didSelectVideo: nil)
            }
            self.pickerController(picker, didSelectVideo: video)
        }

    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
