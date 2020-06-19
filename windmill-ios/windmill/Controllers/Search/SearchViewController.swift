//
//  SearchViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-13.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit
import SwiftKeychainWrapper

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: IVARS

    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var timer: Timer!
    
    let searchManager = SearchManager()
    
    var usersData: [User] = []
    
    // MARK: Lifecycle
     
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchTableView.delegate = self
        searchTableView.dataSource = self
        initGraphics()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationItem.backBarButtonItem = nil
        
        let icon3 = UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let button3 = UIButton()
        button3.frame = CGRect(x:0, y:0, width: 51, height: 31)
        button3.setImage(icon3, for: .normal)
        let barButton3 = UIBarButtonItem()
        barButton3.customView = button3
        self.navigationController?.navigationItem.leftBarButtonItem = barButton3
    }
    
    // MARK: User Interface
    
    func initGraphics() {
        let green = UIColor(rgb: 0x00B894)
        
        searchBar.layer.borderColor = green.cgColor
        searchBar.layer.borderWidth = 1.0
        searchBar.layer.cornerRadius = 10.0
        
        searchTableView.rowHeight = 100.0
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .white
    
    }
    
    // MARK: API Functions
    
    func searchUsers() {
        searchManager.searchForUsers(substring: searchBar.text!) { (data) in
            do {
                self.usersData = []
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                let users = jsonResponse["users"] as! [[String:Any]]
                for i in 0..<users.count {
                    var user = User(dictionary: users[i])!
                    
                    let relations = users[i]["relations"] as! [String:Any]

                    let r = Relations(dictionary: relations)
                    
                    user.relations = r!
                    
                    self.usersData.append(user)
                }
                
                DispatchQueue.main.async {
                    self.searchTableView.reloadData()
                }
                
            } catch let parsingError {
                 print("Error", parsingError)
            }
        }
    }
    
    @objc func reload() {
        searchUsers()
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let username = KeychainWrapper.standard.string(forKey: "username")
        if let cell = sender as? UITableViewCell {
            let i = searchTableView.indexPath(for: cell)!.row
            if segue.identifier == "searchToProfileSegue" {
                let vc = segue.destination as! ProfileViewController
                if cell.textLabel?.text == username! {
                    vc.currentUserProfile = true
                    vc.followingUser = self.usersData[i]
                }
                else {
                    vc.currentUserProfile = false
                    vc.followingUser = self.usersData[i]
                }
            }
        }
    }
    
    // MARK: Search Delegate Functions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            usersData = []
            searchTableView.reloadData()
            return
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(SearchViewController.reload), object: nil)
        self.perform( #selector(SearchViewController.reload), with: nil, afterDelay: 1.0)

    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
    }
    
    // MARK: TableView Delegate Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        cell.textLabel?.text = usersData[indexPath.item].username
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        searchTableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "searchToProfileSegue", sender: cell)
    }
}
