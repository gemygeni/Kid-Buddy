//
//  ChildProfileViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 8/30/21.
//

import UIKit
import Firebase
import UniformTypeIdentifiers
class ChildProfileViewController: UIViewController {
    weak var fetchedImage : UIImage?
    var invitationUrl : URL?
    var childAccount : User?{
        didSet{
            childName = childAccount?.name
        }
    }
    var childName : String?{
        didSet{
            childNameLabel?.text = childName
        }
    }
    
    var ProfileImage : UIImage? {
        get{
            return profileImageView.image ?? #imageLiteral(resourceName: "person")
        }
        set {
            profileImageView.image = newValue ?? #imageLiteral(resourceName: "person")
            profileImageView.translatesAutoresizingMaskIntoConstraints = false
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
        childNameLabel?.text = childAccount?.email ?? "email"
        navigationItem.title = childName
    }
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var childNameLabel: UILabel!
    
    @IBAction func ChatButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "ShowChatSegue", sender: self)
    }
    
    @IBAction func ObservePlacesButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: "ShowObservedPlacesSegue", sender: self)
    }
    @IBAction func EditButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showEditChildProfileSegue", sender: self)
    }
    
    // MARK: - function to remove all child account from database.
    @IBAction func unpairChildPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "are you sure you want to remove account", message: "caution: you will lose all data related to this account", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            let childId = self?.childAccount?.uid
            DataHandler.shared.removeChild(withId: childId!)
            self?.navigationController?.popViewController(animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowChatSegue"{
            if let chatVC = segue.destination.contents as? ChatViewController{
                chatVC.childID = childAccount?.uid
                print("here 101 \(String(describing: chatVC.childID))")
                chatVC.profileImage = fetchedImage
                chatVC.childName  = childAccount?.name ?? ""
            }
        }
        else if segue.identifier == "showEditChildProfileSegue"{
            if let editingVC = segue.destination as? EditChildProfileViewController{
                editingVC.fetchedImage = fetchedImage
                editingVC.childName = childAccount?.name ?? ""
                editingVC.childId   = childAccount?.uid
                editingVC.delegate = self
            }
        }
    }
}

// MARK: - ChangedInfoDelegate Method
extension ChildProfileViewController : ChangedInfoDelegate{
    // MARK: function triggered when child profile edited to update data
    func didChangedInfo(_ sender: EditChildProfileViewController, newImage: UIImage, newName: String) {
        ProfileImage = newImage
        childName = newName
    }
}
