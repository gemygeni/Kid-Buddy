//
//  ChildProfileViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 8/30/21.
//

import UIKit
import Firebase
import SwiftOTP
class ChildProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    @IBOutlet weak var childNameLabel: UILabel!
    
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
        //(childName ?? "name")+"\n"+(childAccount?.email ?? "email")
        navigationItem.title = childName
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
    
    @IBAction func EditButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showEditChildProfileSegue", sender: self)
    }
    
    @IBAction func sendLinkButtonPressed(_ sender: UIButton) {
        configureDynamicLink()
    }
    

    @IBAction func unpairChildPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "are you sure you want to remove account", message: "caution: you will lose all data related to this account", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            let childId = self?.childAccount?.uid
            guard let parentId = Auth.auth().currentUser?.uid else {return}
           DataHandler.shared.removeChild(of: parentId, withId: childId!)
                self?.navigationController?.popViewController(animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    

    
    func configureDynamicLink(){
        var components = URLComponents()
        components.scheme = "https"
        components.host = "apps.apple.com/app/1600337105"
        guard let linkParameter = components.url else { return }
        print("I am sharing \(linkParameter.absoluteString)")
        let domain = "https://trackids.page.link"
        guard let linkBuilder = DynamicLinkComponents
          .init(link: linkParameter, domainURIPrefix: domain) else {
            return
        }
        if let myBundleId = Bundle.main.bundleIdentifier {
          linkBuilder.iOSParameters = DynamicLinkIOSParameters(bundleID: myBundleId)
        }
        linkBuilder.iOSParameters?.appStoreID = "1600337105"
        linkBuilder.socialMetaTagParameters = DynamicLinkSocialMetaTagParameters()
        guard let uid =   Auth.auth().currentUser?.uid else{return}
        guard let data = Data(base64Encoded: uid) else{return}
        if let totp = TOTP(secret: data) {
            if  let otpString = totp.generate(time: Date()){
            linkBuilder.socialMetaTagParameters?.title = "install app on your kid's device by this link & Join kid with this code: \(otpString) "
            print("otp is \(String(describing: otpString))")
                OTPReference.child(String(describing: otpString)).updateChildValues(["parentId": uid])
           }
        }
        linkBuilder.socialMetaTagParameters?.descriptionText = "if you recieved this link from your parents install kid buddy "
        guard let longURL = linkBuilder.url else { return }
        print("The long dynamic link is \(longURL.absoluteString)")
        linkBuilder.shorten {[weak self] url, warnings, error in
            if let error = error {
                print("Oh no! Got an error! \(error)")
                return
            }
            if let warnings = warnings {
                for warning in warnings {
                    print("Warning: \(warning)")
                }
            }
            guard let url = url else { return }
            print("I have a short dynamic link to share! \(url.absoluteString)")
            self?.shareItem(with: url)
        }
    }
    
    func shareItem(with url: URL) {
        let subjectLine = ""
        let activityView = UIActivityViewController(activityItems: [subjectLine, url], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityView, animated: true, completion: nil)
    }
}


extension ChildProfileViewController : ChangedInfoDelegate{
    func didChangedInfo(_ sender: EditChildProfileViewController, newImage: UIImage, newName: String) {
        ProfileImage = newImage
        childName = newName
    }
}
