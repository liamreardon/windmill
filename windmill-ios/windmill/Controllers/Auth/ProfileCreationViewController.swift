//
//  ProfileCreation.swift
//  windmill
//
//  Created by Liam  on 2020-04-27.
//  Copyright © 2020 Liam Reardon. All rights reserved.
//

import Foundation
import UIKit

class ProfileCreationViewController: UIViewController {
    
    let authManager = AuthManager()
    
    @IBOutlet weak var usernameTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func setUsername(_ sender: Any) {
        let username = ["username":usernameTextField.text!]
        let result = authManager.checkUsername(username: username)
        
        if result["available"] as? Int == 1 {
            // Username available
            self.performSegue(withIdentifier: "toProfilePic", sender: nil)
        }
        else {
            // Username taken
            let alert = UIAlertController(title: "Oops", message: "Username is taken, try again!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
    
}
