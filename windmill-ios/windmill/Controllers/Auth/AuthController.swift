//
//  AuthController.swift
//  windmill
//
//  Created by Liam  on 2020-04-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

class AuthController: UIViewController {
    
    let authManager = AuthManager()
    
    @IBOutlet var username: UITextField!
    @IBOutlet var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
            //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))

        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false

        view.addGestureRecognizer(tap)    }
    
    @IBAction func loginPressed(_ sender: Any) {
        let credentials: [String:Any] = [
            "username":username.text!,
            "password":password.text!
        ]
        
        loginUser(params: credentials)

    }
    
    func loginUser(params: [String:Any]) {
    
        authManager.login(params: params)
       
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}


