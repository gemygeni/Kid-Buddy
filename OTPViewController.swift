//
//  OTPViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 23/06/2022.
//

import UIKit
import KWVerificationCodeView
import Firebase

class OTPViewController: UIViewController {
    @IBAction func SubmitButtonPressed(_ sender: UIButton) {
        linkWithParentAccount()
        self.dismiss(animated: true)
    }
    
    
    @IBOutlet weak var VerificationCodeView: KWVerificationCodeView!
    
    func linkWithParentAccount(){
        guard let uid =   Auth.auth().currentUser?.uid else{return}

        if VerificationCodeView.hasValidCode(){
            let otp = VerificationCodeView.getVerificationCode()
            OTPReference.child(otp).observeSingleEvent(of: .value) { snapshot in
                guard let dictionary = snapshot.value as? [String:Any] else {return}
                let parentId = dictionary["parentId"] as! String
                print("parentId is \(parentId)")
                let Reference = UserReference.child(uid)
                Reference.updateChildValues(["parentID" : parentId]) { error, reference in
                    if error != nil{print(error!.localizedDescription)}
                        
                    
                    
                    
                    
                    
                    
                    UserReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
                        guard let userInfo = snapshot.value as? [String : Any] else {return}
                        let name =   userInfo["name"] ?? ""
                        let parenId   =   userInfo["parentID"] ?? ""
                        
                                
                                
                                
                    let storageReference = storage.reference()
                    let imageReference  = storageReference.child("ChildsPictures/\(parenId)/\(name).jpg")
                    if let imageData = #imageLiteral(resourceName: "person.png").jpegData(compressionQuality: 0.3){
                        imageReference.putData(imageData, metadata: nil) { (metadata, error) in
                            if error != nil {print(error!.localizedDescription)}
                            imageReference.downloadURL { [weak self](url, error) in
                                if error != nil {print(error!.localizedDescription)}
                                if let downloadedURL = url{
                                    Reference.updateChildValues(["imageURL" : downloadedURL.absoluteString]) { error, reference in
                                        if error != nil {print(error!.localizedDescription)}
                                        TrackedChildsReference.child(parentId).child(uid).updateChildValues(userInfo) { error, reference in
                                            if error != nil{print(error!.localizedDescription)}
                                                
                                OTPReference.child(otp).removeValue { error, reference in

                        self?.showAlert(withTitle: "Well Done", message: "Successfully added to parent account")
                                                }
                                            }
                                        }
                                     }
                                  }
                            }
                        }
                    }
                }
            }
        }
    }
}
