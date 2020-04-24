//
//  ViewController.swift
//  windmill
//
//  Created by Liam  on 2020-04-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import GoogleSignIn

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        
        // Google Sign In Button
        let googleSignIn = GIDSignInButton(frame: CGRect(x: 0, y: 0, width: 230, height: 48))
        googleSignIn.center = view.center
        view.addSubview(googleSignIn)
        
        let googleSignOut = UIButton(frame: CGRect(x: 50, y: 50, width: 100, height: 30))
        googleSignOut.backgroundColor = UIColor.red
        googleSignOut.setTitle("Sign Out", for: .normal)
        googleSignOut.center = view.center
        googleSignOut.center.y = view.center.y + 100
        googleSignOut.addTarget(self, action: #selector(self.signOut(_:)), for: .touchUpInside)
        self.view.addSubview(googleSignOut)
            
    }
    
    @objc func signOut(_ sender: UIButton) {
        print("signing out...")
        GIDSignIn.sharedInstance()?.signOut()
    }
}

