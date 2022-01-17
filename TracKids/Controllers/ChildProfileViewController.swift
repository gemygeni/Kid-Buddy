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
    var invitationUrl : URL?
    var childAccount : User?
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
        childNameLabel?.text = (childAccount?.name ?? "name")+"\n"+(childAccount?.phoneNumber ?? "phone")
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
                chatVC.profileImage = fetchedImage
                chatVC.childName  = childAccount?.name ?? ""
            }
        }
    }
    
    
    @IBAction func sendLinkButtonPressed(_ sender: UIButton) {
        configureDynamicLink()
    }
    
//    func handleSharing(){
//        let activity = UIActivityViewController(activityItems: ["install app on yor kid device by this link"], applicationActivities: nil)
//        //activity.popoverPresentationController?.barButtonItem = sender
//        present(activity, animated: true, completion: nil)
//        configureDynamicLink()
//    }
    
    func configureDynamicLink(){
        guard let childEmail = childAccount?.email , let childPasssword = childAccount?.password  else {return}
        var components = URLComponents()
        components.scheme = "https"
        components.host = "apps.apple.com/app/1600337105"
        let childEmailQueryItem = URLQueryItem(name: "childEmail", value: childEmail )
        let childPassswordQueryItem = URLQueryItem(name: "childPasssword", value: childPasssword )
        components.queryItems = [childEmailQueryItem, childPassswordQueryItem]
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
        linkBuilder.socialMetaTagParameters?.descriptionText = "if you recieved this link from your parents number install kid buddy to share your location info with them "
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
          print("I have a short url to share! \(url.absoluteString)")
            self?.shareItem(with: url)
        }
   }
    
    
    func shareItem(with url: URL) {
      let subjectLine = "install app on your kid's device by this link"
      let activityView = UIActivityViewController(activityItems: [subjectLine, url], applicationActivities: nil)
      UIApplication.shared.windows.first?.rootViewController?.present(activityView, animated: true, completion: nil)
    }


    
    
    
    
  }

    

