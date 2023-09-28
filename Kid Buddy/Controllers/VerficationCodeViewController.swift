//
//  VerficationCodeViewController.swift
//  Kid Buddy
//
//  Created by AHMED GAMAL  on 23/06/2022.
//

import UIKit
import KWVerificationCodeView
import Firebase

class VerficationCodeViewController: UIViewController {
    var parentId = "parentId"
    var childName = "childName"
    var imageURL = "imageURL"
    let semaphore = DispatchSemaphore(value: 0)
    var userInfo : [String : Any] = ["userInfo" : 1]
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    @IBAction func SubmitButtonPressed(_ sender: UIButton) {
        ActivityIndicator.startAnimating()
        linkWithParentAccount()
    }
    
    @IBOutlet weak var VerificationCodeView: KWVerificationCodeView!
    
    override func viewDidLoad() {
        VerificationCodeView.becomeFirstResponder()
    }
    
    // MARK: - function to link child account with parent account with OTP.
    func linkWithParentAccount(){
        guard let uid = Auth.auth().currentUser?.uid else{return}
        let userReference = userReference.child(uid)
        if VerificationCodeView.hasValidCode(){
            DispatchQueue.global().async {
                let otp = self.VerificationCodeView.getVerificationCode()
                // fetch parent id of child from otp reference of database.
                oTPReference.child(otp).observeSingleEvent(of: .value) { snapshot in
                    guard let dictionary = snapshot.value as? [String:Any] else {return}
                    if let parentId = dictionary["parentId"] as? String{
                        self.parentId = parentId
                        self.semaphore.signal()
                    }
                }
                self.semaphore.wait()
                // update child reference with fetched parent id in database.
                userReference.updateChildValues(["parentID" : self.parentId]) { error, _ in
                    if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                    self.semaphore.signal()
                }
                self.semaphore.wait()
                // fetch child name and parent id from user reference of database.
                userReference.observeSingleEvent(of: .value) { snapshot in
                    guard let userInfo = snapshot.value as? [String : Any] else {return}
                    if let name = userInfo["name"] as? String{
                        self.childName = name
                        self.semaphore.signal()
                    }
                }
                self.semaphore.wait()
                //fetch child image that parent have set to child from storage database.
                let storageReference = storage.reference()
                let imageReference  = storageReference.child("ChildsPictures/\(self.parentId)/\(self.childName).jpg")
                if let imageData = #imageLiteral(resourceName: "person").jpegData(compressionQuality: 0.3){
                    imageReference.putData(imageData, metadata: nil){ (metadata, error) in
                        if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                        self.semaphore.signal()
                    }
                }
                self.semaphore.wait()
                //download image Url form child image Reference
                imageReference.downloadURL { url, error in
                    if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                    if let downloadedURL = url{
                        self.imageURL = downloadedURL.absoluteString
                    }
                    self.semaphore.signal()
                }
                self.semaphore.wait()
                //update image url for child account
                userReference.updateChildValues(["imageURL" : self.imageURL]) { error, _ in
                    if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                    self.semaphore.signal()
                }
                self.semaphore.wait()
                //fetch user info after updating data
                userReference.observeSingleEvent(of: .value) { snapshot in
                    guard let fetchedUserInfo = snapshot.value as? [String : Any] else {return}
                    self.userInfo = fetchedUserInfo
                    self.semaphore.signal()
                }
                self.semaphore.wait()
                //add child account to tracked childs reference of parent.
                trackedChildsReference.child(self.parentId).child(uid).updateChildValues(self.userInfo) { error, _ in
                    if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                    self.semaphore.signal()
                }
                self.semaphore.wait()
                //remove OTP from database after linking done.
                oTPReference.child(otp).removeValue { error, _ in
                    if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                    self.ActivityIndicator.stopAnimating()
                    self.dismiss(animated: true)
                }
            }
        }
        
    }
}
