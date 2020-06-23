//
//  ActivityViewController.swift
//  windmill
//
//  Created by Liam  on 2020-06-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

class ActivityViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: IVARS
    
    @IBOutlet weak var tableView: UITableView!
    let userManager = UserManager()
    internal var activityData: [Activity] = []
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setupUI()
        
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = refreshControl
        } else {
            tableView.addSubview(refreshControl)
        }
        
        refreshControl.addTarget(self, action: #selector(refreshActivity), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getActivity()
    }
    
    @objc internal func refreshActivity() {
        activityData = []
        getActivity()
    }
    
    // MARK: User Interface
    
    internal func setupUI() {
        tableView.rowHeight = 80.0
    }
    
    // MARK: API Functions
    
    internal func getActivity() {
        activityData = []
        userManager.getActivity { (data) in
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                let activity = jsonResponse["activity"] as! [[String:Any]]
                for i in 0..<activity.count {
                    print(activity[i])
                    let a = Activity(dictionary: activity[i])
                    self.activityData.append(a!)
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
                
                
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: TableView Delegate Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.activityData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityCell
        cell.activityImage.layer.borderWidth = 1.6
        cell.activityImage.layer.masksToBounds = false
        cell.activityImage.layer.borderColor = UIColor.white.cgColor
        cell.activityImage.layer.cornerRadius = cell.activityImage.frame.height / 2
        cell.activityImage.clipsToBounds = true
        cell.activityLabel.text = activityData[indexPath.item].body
        cell.activityImage.sd_setImage(with: URL(string: activityData[indexPath.item].image!), placeholderImage: UIImage(named: ""))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }
    
}
