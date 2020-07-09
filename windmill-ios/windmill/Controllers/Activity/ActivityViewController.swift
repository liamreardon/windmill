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

    internal var activityData: [Activity] = []
    internal var itemsToInsert: [Activity] = []
    let refreshControl = UIRefreshControl()
    let userManager = UserManager()
    
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
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        getActivity()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationItem.backBarButtonItem = nil
    }
    
    @objc internal func refreshActivity() {
        getActivity()
    }
    
    // MARK: User Interface
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
          return .darkContent
    }
    
    internal func setupUI() {
        tableView.rowHeight = 80.0
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .white
    }
    
    // MARK: API Functions
    
    internal func getActivity() {
        userManager.getActivity { (data) in
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                let activity = jsonResponse["activity"] as! [[String:Any]]
                var activities: [Activity] = []
                for i in 0..<activity.count {
                    var a = Activity(dictionary: activity[i])
                    let post = activity[i]["post"] as! [String:Any]
                    let comment = activity[i]["comment"] as! [String:Any]
                    a?.post = Post(dictionary: post)
                    a?.comment = Comment(dictionary: comment)
                    activities.insert(a!, at: 0)
                }
            
                DispatchQueue.main.async {
                    if self.activityData.count > 0 {
                        var idxToRemove: [Int] = []
                        self.itemsToInsert = []
                        
                        for i in 0..<self.activityData.count {
                            var found = false
                            for j in 0..<activities.count {
                                if self.activityData[i].id == activities[j].id {
                                    found = true
                                }
                            }
                            if !found {
                                idxToRemove.append(i)
                            }
                        }
                        
                        for i in 0..<idxToRemove.count {
                            let idx = idxToRemove[i]
                            self.activityData.remove(at: idx)
                            let indexPath = IndexPath(item: idx, section: 0)
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                        
                        for i in 0..<activities.count {
                            var newItem = true
                            for j in 0..<self.activityData.count {
                                if activities[i].id == self.activityData[j].id {
                                    newItem = false
                                    break
                                }
                            }
                            if newItem {
                                self.itemsToInsert.append(activities[i])
                            }
                        }
                    }
                    
                    if self.activityData.count == 0 {
                        self.activityData = activities
                    }
                    else {
                        
                        for i in 0..<self.itemsToInsert.count {
                            let item = self.itemsToInsert[i]
                            self.activityData.insert(item, at: 0)
                            self.tableView.beginUpdates()
                            self.tableView.insertRows(at: [
                                (NSIndexPath(row: 0, section: 0) as IndexPath)], with: .automatic)
                            self.tableView.endUpdates()
                        }
                    }
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
                
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let cell = sender as? ActivityCell {
            let i = tableView.indexPath(for: cell)!.row
            let activity = activityData[i]
            if segue.identifier == "activityToProfileSegue" {
                let vc = segue.destination as! ProfileViewController
                vc.currentUserProfile = false
                vc.fromActivity = true
                vc.passedUsername = activity.username
            }
            else if segue.identifier == "activityToVideoSegue" {
                let vc = segue.destination as! ChildViewController
                vc.post = activity.post
                vc.fromActivity = true
            }
        }
    }
    
    // MARK: Table View Delegate Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "activityCell", for: indexPath) as! ActivityCell
        cell.update(for: activityData[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ActivityCell
        tableView.deselectRow(at: indexPath, animated: true)
        if cell.activity.type == "FOLLOWED" {
            performSegue(withIdentifier: "activityToProfileSegue", sender: cell)
        }
        else {
            performSegue(withIdentifier: "activityToVideoSegue", sender: cell)
        }
    }

    
}
