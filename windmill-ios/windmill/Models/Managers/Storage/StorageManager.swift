//
//  StorageManager.swift
//  windmill
//
//  Created by Liam  on 2020-05-14.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

enum StorageType {
    case userDefaults
    case fileSystem
}

struct StorageManager {
    
    func store(image: UIImage, forKey key: String, withStorageType storageType: StorageType) {
        if let pngRepresentation = image.pngData() {
            switch storageType {
            case .fileSystem:
                if let filePath = filePath(forKey: key) {
                    do {
                        try pngRepresentation.write(to: filePath, options: .atomic)
                    } catch let error {
                        print("Saving results in error", error)
                    }
                }
            case .userDefaults:
                UserDefaults.standard.set(pngRepresentation, forKey: key)
            }
        }
    }
    
    func retrieveImage(forKey key: String, inStorageType storageType: StorageType) -> UIImage? {
        switch storageType {
        case .fileSystem:
            if let filePath = self.filePath(forKey: key),
                let fileData = FileManager.default.contents(atPath: filePath.path),
                let image = UIImage(data: fileData) {
                return image
            }
            
            
        case .userDefaults:
            if let imageData = UserDefaults.standard.object(forKey: key) as? Data,
                let image = UIImage(data: imageData) {
                return image
            }
        }
        
        return nil
    }
    
    func removeImage(forKey key: String, inStorageType storageType: StorageType) {
        switch storageType {
        case .fileSystem:
            if let filePath = self.filePath(forKey: key) {
                do {
                    try FileManager.default.removeItem(at: filePath)
                } catch let error {
                    print("Error removing image", error.localizedDescription)
                }
            }
            
        case .userDefaults:
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentURL.appendingPathComponent(key + ".png")
    }
}
