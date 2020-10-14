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
import SDWebImage

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: IVARS

    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var timer: Timer!
    var usersData: [User] = []
    var vSpinner: UIView?
    
    let searchManager = SearchManager()
    let refreshControl = UIRefreshControl()
    
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

        searchBar.layer.cornerRadius = 10.0
        
        searchTableView.rowHeight = 80.0
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .white
        
        searchTableView.keyboardDismissMode = .interactive
    
    }
    
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        let ai = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.large)
        ai.color = .white
        ai.startAnimating()
        ai.center = spinnerView.center
       
        spinnerView.addSubview(ai)
        onView.addSubview(spinnerView)
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            self.vSpinner?.removeFromSuperview()
            self.vSpinner = nil
        }

    }
    
    // MARK: User Interaction
    
    @objc internal func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: API Functions
    
    func searchUsers() {
        showSpinner(onView: view)
        searchManager.searchForUsers(substring: searchBar.text!) { (data) in
            do {
                self.usersData = []
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                let users = jsonResponse["users"] as! [[String:Any]]
                for i in 0..<users.count {
                    var user = User(dictionary: users[i])!
                    
                    let relations = users[i]["relations"] as! [String:Any]

                    let r = Relations(dictionary: relations)
                    
                    let numPosts = users[i]["numPosts"] as! Int
                    
                    user.relations = r!
                    
                    user.numPosts = numPosts
                    
                    self.usersData.append(user)
                }
                
                DispatchQueue.main.async {
                    self.removeSpinner()
                    self.searchTableView.reloadData()
                }
                
            } catch let parsingError {
                self.removeSpinner()
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
        if let cell = sender as? SearchCell {
            let i = searchTableView.indexPath(for: cell)!.row
            if segue.identifier == "searchToProfileSegue" {
                let vc = segue.destination as! ProfileViewController
                if cell.user?.username == username! {
                    vc.currentUserProfile = true
                    vc.otherUser = self.usersData[i]
                    vc.fromSearch = true
                }
                else {
                    vc.currentUserProfile = false
                    vc.otherUser = self.usersData[i]
                    vc.fromSearch = true
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
            removeSpinner()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! SearchCell
        cell.user = usersData[indexPath.row]
        cell.displayPicture.layer.borderWidth = 1.6
        cell.displayPicture.layer.masksToBounds = false
        cell.displayPicture.layer.borderColor = UIColor.white.cgColor
        cell.displayPicture.layer.cornerRadius = cell.displayPicture.frame.height / 2
        cell.displayPicture.clipsToBounds = true
        cell.displayPicture.sd_imageIndicator = SDWebImageActivityIndicator.white
        cell.displayPicture.sd_setImage(with: URL(string: usersData[indexPath.row].displaypicture!), placeholderImage: UIImage(named: ""))
        
        let numFollowers = usersData[indexPath.row].relations?.followers?.count
        var followersLabel = ""
        if numFollowers == 1 {
            followersLabel = "1 follower"
        }
        else {
            followersLabel = "\(numFollowers!) followers"
        }
        
        cell.followersLabel.text = followersLabel
        
        let numVideos = usersData[indexPath.row].numPosts
        var videosLabel = ""
        if numVideos == 1 {
            videosLabel = "1 video"
        }
        else {
            videosLabel = "\(numVideos!) videos"
        }
        
        cell.videosLabel.text = videosLabel
        
        if usersData[indexPath.row].verified! {
            let fullString = NSMutableAttributedString(string: "\(usersData[indexPath.row].username!)")
            let image1Attachment = NSTextAttachment()
            let icon = UIImage(systemName: "checkmark.seal.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .bold))?.withTintColor(UIColor(rgb: 0x1da1f2), renderingMode: .alwaysOriginal)
            image1Attachment.image = icon
            let image1String = NSAttributedString(attachment: image1Attachment)
            fullString.append(image1String)
            cell.usernameLabel.attributedText = fullString
        }
        else {
            cell.usernameLabel.text = usersData[indexPath.row].username
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        searchTableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "searchToProfileSegue", sender: cell)
    }
    
}
