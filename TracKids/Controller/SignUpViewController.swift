//
//  SigndUpViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/25/21.
//

import UIKit
import Firebase
import GeoFire

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    @IBOutlet weak var userTypeControl: UISegmentedControl!
    let location = LocationHandler.shared.locationManager.location
    var child = Child(name: "medo", phoneNumber: "010666666")
    
    @IBAction func signUpPressd(_ sender: UIButton) {
        print("location\(String(describing: location))")
        handleSignUp()
    }
    
    @IBAction func CancelPressed(_ sender: UIButton) {
        
        DispatchQueue.main.async {
            self.dismiss(animated: true)
            self.navigationController?.popToRootViewController(animated: true)
        }
     }
    
    
    @IBAction func signInPressed(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
        }
    }
    
   
  
    private func handleSignUp(){
        let userType = userTypeControl.selectedSegmentIndex
        guard let email = emailTextField.text else {return}
        guard let password = passwordTextField.text else {return}
        guard let phoneNumber = phoneNumberTextField.text else {return}
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error{
                print(error.localizedDescription)
            }
            guard let UId = result?.user.uid else {return}
            
            let UserInfo = ["userType" : userType, "email" : email, "password" : password, "phoneNumber" : phoneNumber] as [String : Any]
            Database.database().reference().child("users").child(UId).updateChildValues(UserInfo) { (error, reference) in
                if let error = error{
                    print(error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                self.dismiss(animated: true)
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
}

