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
            self.dismiss(animated: true) {
                print("alhamdo lellah")
            }
            
                            }
        navigationController?.popToRootViewController(animated: true)
            }
    
    
    
    
    
    
    
    
    
    
    
    
        }
        
       
    
    

