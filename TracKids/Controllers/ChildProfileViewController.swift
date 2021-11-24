//
//  ChildProfileViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 8/30/21.
//

import UIKit
import Firebase
class ChildProfileViewController: UIViewController {
    
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var childNameLabel: UILabel!
    
    
    weak var fetchedImage : UIImage?
     var name : String?
     var phone :String?
    var childID : String?
    
    var ProfileImage : UIImage? {
        get{
            return profileImageView.image ?? #imageLiteral(resourceName: "person")
        }
        set {
            profileImageView.image = newValue ?? #imageLiteral(resourceName: "person")
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
           // profileImageView.layer.cornerRadius = ((profileImageView.frame.height) + (profileImageView.frame.width)) / 4.0
           
            profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2.5

            profileImageView.layer.masksToBounds = true

            profileImageView.contentMode = .scaleAspectFill
        }
    }
    override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
        profileImageView.layer.masksToBounds = true
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2.5
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ProfileImage = fetchedImage
        childNameLabel?.text = (name ?? "name")+"\n"+(phone ?? "phone")
    }
    
    
    
    @IBAction func ChatButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowChatSegue", sender: self)
    }
    
    
    @IBAction func ObservePlacesButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "ShowObservedPlacesSegue", sender: self)
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowChatSegue"{
            if let chatVC = segue.destination.contents as? ChatViewController{
                chatVC.childID = childID!
                chatVC.profileImage = fetchedImage
                chatVC.childName  = self.name ?? ""
           }
        }
    }
}
