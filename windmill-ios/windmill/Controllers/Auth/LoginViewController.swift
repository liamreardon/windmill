//
//  ViewController.swift
//  windmill
//
//  Created by Liam  on 2020-04-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import UIKit
import GoogleSignIn

class LoginViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        
        // Google Sign In Button
        let googleSignIn = GIDSignInButton(frame: CGRect(x: 0, y: 0, width: 230, height: 48))
        googleSignIn.center = view.center
        view.addSubview(googleSignIn)
            
    }
    
    @objc func signOut(_ sender: UIButton) {
        print("signing out...")
        GIDSignIn.sharedInstance()?.signOut()
    }
}
