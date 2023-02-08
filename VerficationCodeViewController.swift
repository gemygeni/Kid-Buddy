//
//  VerficationCodeViewController.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 23/06/2022.
//

import UIKit
import KWVerificationCodeView
import Firebase

class VerficationCodeViewController: UIViewController {

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
            guard let uid =   Auth.auth().currentUser?.uid else{return}
            if VerificationCodeView.hasValidCode(){
                let otp = VerificationCodeView.getVerificationCode()
                // fetch parent id of child from otp reference of database.
                OTPReference.child(otp).observeSingleEvent(of: .value) { snapshot in
                    guard let dictionary = snapshot.value as? [String:Any] else {return}
                    let parentId = dictionary["parentId"] as! String
                    // update child reference with fetched parent id in database.
                    let Reference = UserReference.child(uid)
                    Reference.updateChildValues(["parentID" : parentId]) { error, reference in
                        if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                        // fetch child name and parent id from user reference of database.
                        UserReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
                            guard let userInfo = snapshot.value as? [String : Any] else {return}
                            let name =   userInfo["name"] ?? ""
                            let parenId  =   userInfo["parentID"] ?? ""
                            //fetch child image that parent have set to child from storage database.
                            let storageReference = storage.reference()
                            let imageReference  = storageReference.child("ChildsPictures/\(parenId)/\(name).jpg")
                            if let imageData = #imageLiteral(resourceName: "person.png").jpegData(compressionQuality: 0.3){
                                imageReference.putData(imageData, metadata: nil) { (metadata, error) in
                                    if error != nil {print("Debug: error \(String(describing: error!.localizedDescription))")}
                                    imageReference.downloadURL { [weak self](url, error) in
                                        if error != nil {print("Debug: error \(String(describing: error!.localizedDescription))")}
                                        if let downloadedURL = url{
                                            Reference.updateChildValues(["imageURL" : downloadedURL.absoluteString]) { error, _ in
                                                if error != nil {print("Debug: \(error!.localizedDescription)")}
                                                //add child account to tracked child reference of parent.
                                                let trackedChildsReference = TrackedChildsReference.child(parentId).child(uid)
                                                trackedChildsReference.updateChildValues(userInfo) { error, reference in
                                                    if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                                                    trackedChildsReference.updateChildValues(["imageURL" : downloadedURL.absoluteString]) { error, _ in
                                                        if error != nil {print("Debug: \(error!.localizedDescription)")}
                                                        //remove OTP from database after linking done for security issues.
                                                        OTPReference.child(otp).removeValue { error, _ in
                                                            //inform user that linking has done
                                                            if error != nil {print("Debug: \(error!.localizedDescription)")}
                                                            self?.ActivityIndicator.stopAnimating()
                                                            self?.dismiss(animated: true)
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
    }



