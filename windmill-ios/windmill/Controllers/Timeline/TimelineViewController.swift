//
//  TImelineViewController.swift
//  windmill
//
//  Created by Liam  on 2020-06-20.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import GoogleSignIn
import Pageboy
import SwiftKeychainWrapper
import AVFoundation
import SDWebImage

class TimelineViewController: PageboyViewController {
    
    // MARK: IVARS

    var previousBarButton: UIBarButtonItem?
    var nextBarButton: UIBarButtonItem?
    let feedManager = FeedManager()
    var postsData: [Post] = []
    var pageControllers: [ChildViewController] = []
    var profileTapIndex: Int!
    var refreshControl = UIRefreshControl()
    var feedLoaded: Bool = false
    var vSpinner: UIView?
    
    var currentUserProfile: Bool = true
    var currentUser: User?

    @IBOutlet var homeView: UIView!

    // Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.delegate = UIApplication.shared.delegate as? UITabBarControllerDelegate
        
        getFeed()
        dataSource = self
        delegate = self
        navigationOrientation = .vertical
        
        if !feedLoaded {
            showSpinner(onView: homeView)
        }
        
        initGraphics()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if feedLoaded {
            self.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if pageControllers.count == 0 { return }
        let vc = pageControllers[profileTapIndex]
        vc.stop()
    }
    
    override func viewWillDisappear(_ animated: Bool) {

    }
    
    @objc func refresh() {
        self.refreshControl.beginRefreshing()
        self.reloadData()
    }
    
    // MARK: Pageboy Data Source
    
    func createPageControllers() {
        
        if pageControllers.count > 0 {
            pageControllers = []
        }
        
        let storyboard = UIStoryboard(name: "WindmillMain", bundle: Bundle.main)
        
        if postsData.count == 0 { return }

        for i in 0 ..< postsData.count {
            let viewController = storyboard.instantiateViewController(withIdentifier: "ChildViewController") as! ChildViewController
            viewController.index = i + 1
            viewController.post = postsData[i]
            pageControllers.append(viewController)
        }
    }
    
    func updateVideoLoop(index: Int, direction: PageboyViewController.NavigationDirection) {

//        let vc = pageControllers[index]
//
//        switch direction {
//        case .forward:
//            let prevVC = pageControllers[index-1]
//            prevVC.stop()
//        case .reverse:
//            let prevVC = pageControllers[index+1]
//            prevVC.stop()
//        default:
//            print("")
//        }
//
//        vc.play()
    }

    // MARK: API Functions
  
    func getFeed() {
        if postsData.count > 0 {
            postsData = []
        }
    
        feedManager.getUserFeed(username: currentUser!.username!) { (data) in
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                let posts = jsonResponse["posts"] as! [[String:Any]]
                for i in 0..<(posts.count) {
                    let p = Post(dictionary: posts[i])!
                    self.postsData.append(p)
                }
                
                DispatchQueue.main.async {
                    self.createPageControllers()
                    self.reloadData()
                    self.removeSpinner()
                    self.feedLoaded = true
                    self.scrollToPage(.at(index: self.profileTapIndex), animated: false)
                    self.reloadData()
                }
                
            } catch let parsingError {
                 print("Error", parsingError)
            }
        }
    }
    
    // MARK: User Interface
    
    func showSpinner(onView: UIView) {
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
        vSpinner?.removeFromSuperview()
        vSpinner = nil
    }
    
    func initGraphics() {
        
        let icon3 = UIImage(systemName: "arrow.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .bold))?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let button3 = UIButton()
        button3.frame = CGRect(x:0, y:0, width: 51, height: 31)
        button3.setImage(icon3, for: .normal)
        button3.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
        let barButton3 = UIBarButtonItem()
        barButton3.customView = button3
        self.navigationItem.leftBarButtonItem = barButton3
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: User Interaction
    
    @objc internal func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
}

// MARK: Pageboy Data Source

extension TimelineViewController: PageboyViewControllerDataSource {
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return pageControllers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController,
                        at index: PageboyViewController.PageIndex) -> UIViewController? {
        return pageControllers[index]
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil
    }
}

// MARK: Pageboy Delegates

extension TimelineViewController: PageboyViewControllerDelegate {
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               willScrollToPageAt index: Int,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {
        if feedLoaded {
            self.profileTapIndex = index
            updateVideoLoop(index: index, direction: direction)
        }
        

    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didScrollTo position: CGPoint,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {
        
   
    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didScrollToPageAt index: Int,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {

    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didReloadWith currentViewController: UIViewController,
                               currentPageIndex: PageboyViewController.PageIndex) {
    }
}
