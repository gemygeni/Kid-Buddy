//
//  SignInViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/29/21.
//

import UIKit
import  Firebase

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func signInPressd(_ sender: UIButton) {
        handleSignIn()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }
    private func handleSignIn(){
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            if let error = error {
                print("Failed to log user in due to: \(error.localizedDescription)")
                return}
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    self.navigationController?.popToRootViewController(animated: true)
                    print("signed in successfully")
                    
                }
            }
            
        }
        
    }
    
}


extension UIViewController {
    var navcon : UIViewController {
        if let VC = self as? UINavigationController {
            return VC.visibleViewController ?? self
        }
        else {
            return self
        }
    }
}




