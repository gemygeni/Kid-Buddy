//
//  ViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/25/21.
//

import UIKit
import Firebase

class ListViewController: UIViewController {

    var user : User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserInfo()
    }

    func fetchUserInfo(){
        DataHandler.shared.fetchUserInfo() { (user) in
            self.user = user
            if user.accountType == 1{
                self.childsButton.isHidden = true
                self.settingsButton.isHidden = true
           }
        }
    }
    
    
    @IBOutlet weak var childsButton: UIButton!
    
    
    @IBOutlet weak var settingsButton: UIButton!
    
    
    
    
    
    
    
    @IBOutlet weak var signInButton: UIButton!{
        didSet{
            signInButton.isHidden = Auth.auth().currentUser?.uid != nil
        }
    }
    @IBAction func signOutPressed(_ sender: UIButton) {
        handleSignOut()
    }
    
    
    @IBOutlet weak var signOutButton: UIButton!{
        didSet{
            signOutButton.isHidden = Auth.auth().currentUser?.uid == nil
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
    
    @IBAction func childsButtonPressed(_ sender: UIButton) {
        
        performSegue(withIdentifier: "ChildsListSegue", sender: self)
    }
    
    
    @IBAction func shareAppPressed(_ sender: UIButton) {
        handleSharing()
    }
    func   handleSharing(){
        let activity = UIActivityViewController(activityItems: ["invite to join trackids"], applicationActivities: nil)
        //activity.popoverPresentationController?.barButtonItem = sender
        present(activity, animated: true, completion: nil)
    }

    
}

