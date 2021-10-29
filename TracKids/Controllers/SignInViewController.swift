//
//  SignInViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/29/21.
//

import UIKit
import  Firebase

class SignInViewController: UIViewController  {
//var handle : AuthStateDidChangeListenerHandle?
    
//    override func viewWillAppear(_ animated: Bool) {
    //        super.viewWillAppear(true)
//
//        handle = Auth.auth().addStateDidChangeListener { _, user in
//          if user == nil {
//            self.emailTextField.text = nil
//            self.passwordTextField.text = nil
//          }
//          else {
//           // self.performSegue(withIdentifier: self.loginToList, sender: nil)
//            self.emailTextField.text = nil
//            self.passwordTextField.text = nil
//          }
//        }
//    }
    
    
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
    
    @IBAction func signInPressed(_ sender: UIButton) {
        handleSignIn()
    }
    
    
    func tapRecognnizer(){
        let taprecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(taprecognizer)
    }
    
    @objc func handleTap(){
        view.endEditing(true)
    }
    
    @IBAction func CancelPressed(_ sender: Any) {
        DispatchQueue.main.async {
                self.dismiss(animated: true) {
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.becomeFirstResponder()
    }
    
    
    private func handleSignIn(){
        guard let email = emailTextField.text ,
         let password = passwordTextField.text,
        !email.isEmpty,!password.isEmpty else {return}
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (user, error) in
            if let error = error, user == nil {
                let alert = UIAlertController(title: "Sign In Failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true, completion: nil)
                self?.emailTextField.text = nil
                self?.passwordTextField.text = nil
                }
            
            else{
                DispatchQueue.main.async {
                    self?.dismiss(animated: true) {
                        self?.navigationController?.popToRootViewController(animated: true)
                        print("signed in successfully")
                    }
                }
            }
        }
    }
}

extension SignInViewController : UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSignIn()
        textField.resignFirstResponder()
        return true
    }
    
}





