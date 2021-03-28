//
//  ViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/25/21.
//

import UIKit
import Firebase

class ListViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    
    @IBOutlet weak var SignInButton: UIButton!{
        didSet{
            SignInButton.isHidden = Auth.auth().currentUser?.uid != nil
        }
    }
    @IBAction func signOutPressed(_ sender: UIButton) {
        handleSignOut()
    }
    
    
    @IBOutlet weak var SignOutButton: UIButton!{
        didSet{
            SignOutButton.isHidden = Auth.auth().currentUser?.uid == nil
        }
    }
    private func handleSignOut(){
        do {
            try! Auth.auth().signOut()
        }
       
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                print("signed out successfully")
            }
            self.navigationController?.popToRootViewController(animated: true)
                 }
    }
    
    
    
}

