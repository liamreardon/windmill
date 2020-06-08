//
//  HomeViewController.swift
//  windmill
//
//  Created by Liam  on 2020-04-28.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import GoogleSignIn
import Pageboy
import SwiftKeychainWrapper
import AVFoundation

class HomeViewController: PageboyViewController {
    
    // MARK: IVARS

    var previousBarButton: UIBarButtonItem?
    var nextBarButton: UIBarButtonItem?
    let feedManager = FeedManager()
    var postsData: [Post] = []
    var pageControllers: [ChildViewController] = []
    var index: Int = 0
    var refreshControl = UIRefreshControl()
    var feedLoaded: Bool = false
    var vSpinner : UIView?

    @IBOutlet var homeView: UIView!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFeed()
        
        dataSource = self
        delegate = self
        navigationOrientation = .vertical
        
        if !feedLoaded {
            showSpinner(onView: homeView)
        }
        
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
        let vc = pageControllers[index]
        vc.stop()
    }
    
    override func viewWillDisappear(_ animated: Bool) {

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

        let vc = pageControllers[index]
        
        switch direction {
        case .forward:
            let prevVC = pageControllers[index-1]
            prevVC.stop()
        case .reverse:
            let prevVC = pageControllers[index+1]
            prevVC.stop()
        default:
            print("default")
        }
        
        vc.play()
    }

    // MARK: API Functions
  
    func getFeed() {
        if postsData.count > 0 {
            postsData = []
        }
        
        let userId = KeychainWrapper.standard.string(forKey: "userId")
    
        feedManager.getUserFeed(userId: userId!) { (data) in
            
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
                }
                
            } catch let parsingError {
                 print("Error", parsingError)
            }
        }
    }
    
    // MARK: User Interface
    
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
        vSpinner?.removeFromSuperview()
        vSpinner = nil
    }
    
}

// MARK: Pageboy Data Source

extension HomeViewController: PageboyViewControllerDataSource {
    
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

extension HomeViewController: PageboyViewControllerDelegate {
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               willScrollToPageAt index: Int,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {
        

    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didScrollTo position: CGPoint,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {

//        updateStatusLabels()
        
   
    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didScrollToPageAt index: Int,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {
        
        self.index = index
        updateVideoLoop(index: index, direction: direction)
//        updateStatusLabels()
    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didReloadWith currentViewController: UIViewController,
                               currentPageIndex: PageboyViewController.PageIndex) {
    }
}
