//
//  AuthController.swift
//  windmill
//
//  Created by Liam  on 2020-04-22.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import SwiftyJSON


class AuthController: UIViewController {
    
    let API_URL = "http://localhost:8080/api/auth"
    let LOGIN = "/login"
    let SIGNUP = "/signup"
    
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
        let credentials: [String:String] = [
            "username":username.text!,
            "password":password.text!
        ]
        loginUser(url: API_URL+LOGIN, params: credentials)
    }
    
    func loginUser(url: String, params: [String:String]) {

        print(url)
        print(params)
    }
    
    //Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
}


