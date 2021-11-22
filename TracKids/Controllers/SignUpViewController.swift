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
    
    let usersReference =  Database.database().reference().child("users")
    
    @IBOutlet weak var nameTextField: UITextField!{
        didSet{
            nameTextField.delegate = self
        }
    }
    
    @IBOutlet weak var emailTextField: UITextField!{
        didSet{
            emailTextField.delegate = self
        }
    }
    
    @IBOutlet weak var passwordTextField: UITextField!{
        didSet{
            passwordTextField.delegate = self
        }
    }
    
    @IBOutlet weak var phoneNumberTextField: UITextField!{
        didSet{
            phoneNumberTextField.delegate = self
        }
    }
    func tapRecognnizer(){
        let taprecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(taprecognizer)
    }
    @objc func handleTap(){
        view.endEditing(true)
    }
    @IBOutlet weak var userTypeControl: UISegmentedControl!
    let location = LocationHandler.shared.locationManager?.location
    
    @IBAction func signUpPressed(_ sender: UIButton) {
        
        handleSignUp()
    }
    
    @IBAction func CancelPressed(_ sender: UIButton) {
        
        DispatchQueue.main.async {
            self.dismiss(animated: true)
            self.navigationController?.popToRootViewController(animated: true)
        }
     }
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.becomeFirstResponder()
    }
    
    @IBAction func signInPressed(_ sender: UIButton) {
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
        }
    }
  
    private func handleSignUp(){
        let userType = userTypeControl.selectedSegmentIndex
        guard let name = nameTextField.text,
              let  email = emailTextField.text,
         let password = passwordTextField.text,
         let phoneNumber = phoneNumberTextField.text, !password.isEmpty,
        !email.isEmpty,!password.isEmpty,!phoneNumber.isEmpty
        else {return}
        
        Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
            if let error = error {
                let alert = UIAlertController(title: "Sign Up Failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true, completion: nil)
                self.emailTextField.text = nil
                self.passwordTextField.text = nil
            }
            guard let UId = result?.user.uid else {return}
            
            let UserInfo = ["name" : name,"email" : email, "phoneNumber" : phoneNumber,"password" : password, "userType" : userType]   as [String : Any]
            self.usersReference.child(UId).updateChildValues(UserInfo) { (error, reference) in
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

extension SignUpViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSignUp()
        textField.resignFirstResponder()
        return true
    }
}
