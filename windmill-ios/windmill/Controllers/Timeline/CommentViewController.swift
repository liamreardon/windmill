//
//  CommentViewController.swift
//  windmill
//
//  Created by Liam  on 2020-06-29.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage
import SwiftKeychainWrapper

class CommentViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: IVARS
    
    internal var height: CGFloat?
    internal var post: Post?
    internal var comments: [Comment] = []

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var displayPicture: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    
    let numberToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
    
    let storageManager = StorageManager()
    let postManager = PostManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        setupUI()
        setupTableView()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        getPostComments()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        addKeyboardChangeFrameObserver(willShow: { [weak self](height) in
            //Update constraints here
            self?.view.setNeedsUpdateConstraints()
            }, willHide: { [weak self](height) in
            //Reset constraints here
            self?.view.setNeedsUpdateConstraints()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObserver()
    }
    
    
    // MARK: User Interface
    
    internal func setupUI() {
        textView.text = "add a comment..."
        textView.textColor = UIColor.lightGray
        numberToolbar.barStyle = .default
        numberToolbar.items = [
        UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelComment)),
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
        UIBarButtonItem(title: "Send", style: .plain, target: self, action: #selector(sendComment))]
        numberToolbar.sizeToFit()
        textView.inputAccessoryView = numberToolbar
        
        let dp = UserDefaults.standard.string(forKey: "dp")
        let userId = KeychainWrapper.standard.string(forKey: "userId")
        let altdp = storageManager.retrieveImage(forKey: userId!+"displayPicture", inStorageType: .fileSystem)
        
        displayPicture.layer.borderWidth = 1.6
        displayPicture.layer.masksToBounds = false
        displayPicture.layer.borderColor = UIColor.white.cgColor
        displayPicture.layer.cornerRadius = displayPicture.frame.height / 2
        displayPicture.clipsToBounds = true
        displayPicture.sd_imageIndicator = SDWebImageActivityIndicator.white
        if dp?.count == 0 {
            displayPicture.image = altdp
        }
        else {
            displayPicture.sd_setImage(with: URL(string: dp!), placeholderImage: UIImage(named: ""))
        }
    }
    
    internal func setupTableView() {
        tableView.estimatedRowHeight = 600.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
    }
    
    // MARK: API Functions
    
    func getPostComments() {
        postManager.getPostComments(postUserId: post!.userId!, postId: post!.id!) { (data) in
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data!, options: []) as! [String:Any]
                let comments = jsonResponse["comments"] as! [[String:Any]]
                
                var cmts: [Comment] = []
                
                for i in 0..<comments.count {
                    let comment = Comment(dictionary: comments[i])
                    cmts.append(comment!)
                }
                
                DispatchQueue.main.async {
                    self.comments = cmts
                    self.tableView.reloadData()
                    self.setupTableView()
                }
            }
            catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: User Interaction
    
    @objc internal func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
         self.view.frame.origin.y = -250 // Move view 150 points upward
    }

    @objc func keyboardWillHide(sender: NSNotification) {
         self.view.frame.origin.y = 0 // Move view to original position
    }
    
    @objc func cancelComment() {
        
    }
    
    @objc func sendComment() {
        let userId = KeychainWrapper.standard.string(forKey: "userId")
        let cmnt = textView.text
        postManager.userCommentedOnPostRequest(postUserId: post!.userId!, userId: userId!, postId: post!.id!, comment: cmnt!) { (data) in
            
        }
    }
    
    // MARK: Text View Delegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.white
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "add a comment..."
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    // MARK: Table View Delegate Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath) as! CommentCell
        cell.update(for: comments[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
