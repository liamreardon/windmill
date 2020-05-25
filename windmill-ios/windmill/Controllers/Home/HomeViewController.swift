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

class HomeViewController: PageboyViewController {
    

    // MARK: Outlets
    
    @IBOutlet weak var offsetLabel: UILabel!
    @IBOutlet weak var pageLabel: UILabel!

    var previousBarButton: UIBarButtonItem?
    var nextBarButton: UIBarButtonItem?
    let feedManager = FeedManager()
    var postsData: [Post] = []
    var pageControllers: [ChildViewController] = []
    var index: Int = 0

    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFeed()
        createPageControllers()
        
        dataSource = self
        delegate = self
        self.navigationOrientation = .vertical
        
        updateStatusLabels()
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let vc = pageControllers[index]
        if vc.isPaused {
            vc.play()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let vc = pageControllers[index]
        vc.stop()
    }

    func updateStatusLabels() {
        let offsetValue =  navigationOrientation == .horizontal ? self.currentPosition?.x : self.currentPosition?.y
        self.offsetLabel.text = "Current Position: " + String(format: "%.3f", offsetValue ?? 0.0)
        self.pageLabel.text = "Current Page: " + String(describing: self.currentIndex ?? 0)
    }
    
    func createPageControllers() {
        let storyboard = UIStoryboard(name: "WindmillMain", bundle: Bundle.main)
        
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
    
    
    // MARK: Actions
    
    @objc func nextPage(_ sender: UIBarButtonItem) {
        scrollToPage(.next, animated: true)
    }
    
    @objc func previousPage(_ sender: UIBarButtonItem) {
        scrollToPage(.previous, animated: true)
    }
    
    // MARK: API Functions
    
    func getFeed() {
        let dGroup = DispatchGroup()
        let userId = KeychainWrapper.standard.string(forKey: "userId")
        dGroup.enter()
        feedManager.getUserFeed(userId: userId!) { (data) in
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                let posts = jsonResponse["posts"] as! [[String:Any]]
                for i in 0..<(posts.count) {
                    let p = Post(dictionary: posts[i])!
                    self.postsData.append(p)
                }
                dGroup.leave()
                
                
            } catch let parsingError {
                 print("Error", parsingError)
            }
            
        }
        dGroup.wait()
        
    }
}

// MARK: PageboyViewControllerDataSource
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

// MARK: PageboyViewControllerDelegate
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

        updateStatusLabels()
        
   
    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didScrollToPageAt index: Int,
                               direction: PageboyViewController.NavigationDirection,
                               animated: Bool) {
        
        self.index = index
        updateVideoLoop(index: index, direction: direction)
        updateStatusLabels()
    }
    
    func pageboyViewController(_ pageboyViewController: PageboyViewController,
                               didReloadWith currentViewController: UIViewController,
                               currentPageIndex: PageboyViewController.PageIndex) {
    }
}
