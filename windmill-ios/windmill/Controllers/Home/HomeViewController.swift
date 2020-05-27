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
    

    // MARK: Init Vars

    var previousBarButton: UIBarButtonItem?
    var nextBarButton: UIBarButtonItem?
    let feedManager = FeedManager()
    var postsData: [Post] = []
    var pageControllers: [ChildViewController] = []
    var pageThumbails: [UIImage] = []
    var index: Int = 0
    var refreshControl = UIRefreshControl()

    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getFeed()
        getPageThumbnails()
        createPageControllers()
        
        dataSource = self
        delegate = self
        navigationOrientation = .vertical
    
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let prevPostDataCount = postsData.count
        getFeed()
        if postsData.count > prevPostDataCount {
            getPageThumbnails()
            createPageControllers()
        }
        
        if pageControllers.count == 0 {
            // show no posts screen
            return
        }
        
        self.reloadData()
        
        let vc = pageControllers[0]
        if vc.isPaused {
            vc.play()
        }
    
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if pageControllers.count == 0 { return }
        let vc = pageControllers[index]
        vc.stop()
    }
    
    
    func createPageControllers() {
        
        if pageControllers.count > 0 {
            pageControllers = []
        }
        
        let storyboard = UIStoryboard(name: "WindmillMain", bundle: Bundle.main)
        
        if postsData.count == 0 { return }
        if pageThumbails.count == 0 { return }
        for i in 0 ..< postsData.count {
            let viewController = storyboard.instantiateViewController(withIdentifier: "ChildViewController") as! ChildViewController
            viewController.index = i + 1
            viewController.post = postsData[i]
            viewController.thumbnail = pageThumbails[i]
            pageControllers.append(viewController)
        }
        
        
    }
    
    func getPageThumbnails() {
        for i in 0 ..< postsData.count {
            let thumbnail = createVideoThumbnail(from: URL.init(string: postsData[i].url!)!)
            pageThumbails.append(thumbnail!)
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
        if postsData.count > 0 {
            postsData = []
        }
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
    
    private func createVideoThumbnail(from url: URL) -> UIImage? {

        let asset = AVAsset(url: url)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.maximumSize = CGSize(width: view.frame.width, height: view.frame.height)

        let time = CMTimeMakeWithSeconds(0.0, preferredTimescale: 600)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            return thumbnail
        }
        catch {
          print(error.localizedDescription)
          return nil
        }

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
