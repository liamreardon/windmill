//
//  CollectionViewCell.swift
//  windmill
//
//  Created by Liam  on 2020-06-05.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit

protocol DataCollectionProtocol {
    func passData(index: Int)
    func deleteData(index: Int)
}

class CollectionViewCell: UICollectionViewCell {
    
    // MARK: IVARS
    
    var index: IndexPath?
    var delegate: DataCollectionProtocol?
    @IBOutlet weak var cellPreviewView: UIView!
    @IBOutlet weak var cellImage: UIImageView!
    
}
