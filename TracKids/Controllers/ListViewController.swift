//
//  ViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 1/25/21.
//

import UIKit
import Firebase
import MessageUI


class ListViewController: UIViewController {
    private var user : User?
    var AuthHandler : AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.user?.uid == nil{
            self.childsButton.isHidden = true
        }
        fetchUserInfo()
    }
    
    @IBOutlet weak var childsButton: UIButton!
    
    @IBOutlet weak var signInButton: UIButton!{
        didSet{
            signInButton.isHidden = Auth.auth().currentUser != nil
        }
    }
    
    @IBOutlet weak var RemoveAccountButton: UIButton!{
        didSet{
            RemoveAccountButton.isHidden = Auth.auth().currentUser == nil
        }
    }
    @IBOutlet weak var signOutButton: UIButton!{
        didSet{
            signOutButton.isHidden = Auth.auth().currentUser == nil
        }
    }

    @IBAction func signOutPressed(_ sender: UIButton) {
        handleSignOut()
        Auth.auth().addStateDidChangeListener() { (auth, firUser) in
        // do something with firUser, e.g. update UI
            
        }
    }
    
    @IBAction func removeAccountPressed(_ sender: UIButton) {
        let alert = UIAlertController(title: "are you sure you want to remove account", message: "caution: you will lose all data related to this account", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            self?.removeAccount()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func childsButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "ChildsListSegue", sender: self)
    }
    
    @IBAction func shareAppPressed(_ sender: UIButton) {
        configureDynamicLink()
    }
    
    @IBAction func sendEmailPressed(_ sender: UIButton) {
        showMailComposer()
    }
    
    @IBAction func sosButtonPressed(_ sender: Any) {
        sendCriticalAlert()
    }
    
    @IBAction func privacyButtonPressed(_ sender: UIButton) {
       performSegue(withIdentifier: "showPrivacyPolicy", sender: self)
    }
    
    
    // MARK: - function to fetch user data from database.
    func fetchUserInfo(){
        DataHandler.shared.fetchUserInfo {[weak self] (user) in
            self?.user = user
            if user.accountType == 1{
                self?.childsButton.isHidden = true
            }
            else if user.accountType == 0 {
                self?.childsButton.isHidden = false
            }
        }
    }
    
    // MARK: - function to handle signing out from database
    private func handleSignOut(){
        do {
            try! Auth.auth().signOut()
            self.navigationController?.popToRootViewController(animated: true)
            if let TrackingVC = self.navigationController?.rootViewController as? TrackingViewController{
                TrackingVC.IsLoggedIn = false
                TrackingVC.mapView.removeAnnotations( TrackingVC.mapView.annotations)
                TrackingVC.centerMapOnUserLocation()
                TrackingVC.tabBarItem.title = ""
                TrackingVC.navigationItem.title = ""
                TrackingVC.childsCollectionView.numberOfItems(inSection: 0)
                TrackingVC.trackedChild = nil
                if var tabVC = tabBarController?.viewControllers{
                    tabVC.removeAll()
                }
            }
            print("Debug: signed out successfully")
        }
    }
    
    // MARK: - function to handle removing all account data from database.
    func removeAccount(){
        let user = Auth.auth().currentUser
        guard  let userId = user?.uid else {return}
        DataHandler.shared.removeAccount(for: userId) {
            user?.delete {[weak self] error in
                if let error = error {
                    print("Debug: error \(String(describing: error.localizedDescription))")} else {
                    print("Debug: Removed completed")
                    self?.navigationController?.popToRootViewController(animated: true)
                    if let TrackingController = self?.navigationController?.rootViewController as? TrackingViewController{
                        TrackingController.IsLoggedIn = false
                        TrackingController.mapView.removeAnnotations( TrackingController.mapView.annotations)
                        TrackingController.centerMapOnUserLocation()
                        self?.handleSignOut()
                    }
                }
            }
        }
    }
    
    // MARK: - function to display mail composer viewcontroller.
    func showMailComposer() {
        guard MFMailComposeViewController.canSendMail() else {
            showAlert(withTitle: "Oops!", message: "sorry, there is an error and your device can't send email ")
            return
        }
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["ahmedgamal.miner@gmail.com"])
        composer.setSubject("HELP!")
        composer.setMessageBody("hey Ahmed ", isHTML: false)
        present(composer, animated: true)
    }
    
    // MARK: - function to configure dynnamic link of the app to share with others.
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
        linkBuilder.socialMetaTagParameters?.title = "Join kid buddy with this link"
        linkBuilder.socialMetaTagParameters?.descriptionText = "install kid buddy to follow your Kids Location in real time"
        guard let longURL = linkBuilder.url else { return }
        print("Debug: sharing The long dynamic link is \(longURL.absoluteString)")
        linkBuilder.shorten {[weak self] url, warnings, error in
            if let error = error {
                print("Debug: Oh no! Got an error in sharing! \(error)")
                return
            }
            if let warnings = warnings {
                for warning in warnings {
                    print("Debug: Warning: \(warning)")
                }
            }
            guard let shortenUrl = url else { return }
            print("Debug: I have a short url to sharing ! \(shortenUrl.absoluteString)")
            let items: [Any] = ["", shortenUrl]
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            self?.present(ac, animated: true)
        }
    }
    
    
    
    // MARK: - function to handle sending Critical Alert to another device.
    func sendCriticalAlert(){
        DataHandler.shared.fetchUserInfo { user in
            let sender = user.name
            if user.accountType == 0 {
                if let childId = TrackingViewController.trackedChildUId{
                    DataHandler.shared.fetchDeviceID(for: childId) { deviceToken in
                        DataHandler.shared.sendCriticalAlert(to: deviceToken, sender: sender, body: "respond to \(sender) call ")
                    }
                }
            }
            else  if user.accountType == 1 {
                guard let parentId = user.parentID  else{return}
                DataHandler.shared.fetchDeviceID(for: parentId) { deviceToken in
                    DataHandler.shared.sendCriticalAlert(to: deviceToken, sender: sender, body: " \(sender) NEEDS HELP ")
                }
            }
        }
    }
}

// MARK: - Mail Compose ViewController Delegate Methods.
extension ListViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if let returnedError = error {
            showAlert(withTitle: "error!", message: "your email can't be sent because that error \(returnedError.localizedDescription)")
            controller.dismiss(animated: true)
            return
        }
        switch result {
        case .cancelled:
            print("Cancelled")
        case .failed:
            print("Failed to send")
        case .saved:
            print("Saved")
        case .sent:
            print("Email Sent")
        @unknown default:
            break
        }
        controller.dismiss(animated: true)
    }
}
