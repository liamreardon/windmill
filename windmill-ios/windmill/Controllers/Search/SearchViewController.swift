//
//  SearchViewController.swift
//  windmill
//
//  Created by Liam  on 2020-05-13.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {


    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var timer: Timer!
    
    let searchManager = SearchManager()
    
    var usersData: [User] = []
     
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        searchTableView.delegate = self
        searchTableView.dataSource = self
        initGraphics()
    }
    
    func searchUsers() {
        searchManager.searchForUsers(substring: searchBar.text!) { (data) in
            do {
                self.usersData = []
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                let users = jsonResponse["users"] as! [[String:Any]]
                for i in 0..<users.count {
                    var user = User(dictionary: users[i])!
                    let posts = users[i]["posts"] as! [[String:Any]]
                    for i in 0..<posts.count {
                        let post = Post(dictionary: posts[i])
                        user.posts!.append(post!)
                    }
                    
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
    
    func initGraphics() {
        let green = UIColor(rgb: 0x00B894)
        
        searchBar.layer.borderColor = green.cgColor
        searchBar.layer.borderWidth = 1.0
        searchBar.layer.cornerRadius = 10.0
        
        searchTableView.rowHeight = 100.0
    
    }
    
    @objc func reload() {
        searchUsers()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? UITableViewCell {
            let i = searchTableView.indexPath(for: cell)!.row
            if segue.identifier == "searchToProfileSegue" {
                let vc = segue.destination as! ProfileViewController
                vc.currentUserProfile = false
                vc.followingUser = self.usersData[i]
            }
        }
    }
    

    // MARK: Search Delegate Functions
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(SearchViewController.reload), object: nil)
        self.perform( #selector(SearchViewController.reload), with: nil, afterDelay: 1.0)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        print("ended")
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        print("started")
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
