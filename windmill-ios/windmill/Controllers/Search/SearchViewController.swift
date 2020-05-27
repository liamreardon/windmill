//
//  SearchViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-13.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

class SearchViewController: UIViewController {
    

    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initGraphics()
    }
    
    func searchUsers() {
        
    }
    
    func initGraphics() {
        let green = UIColor(rgb: 0x00B894)
        
        searchBar.layer.borderColor = green.cgColor
        searchBar.layer.borderWidth = 1.0
        searchBar.layer.cornerRadius = 10.0
        
        searchTableView.rowHeight = 100.0
        
        
    }
}
