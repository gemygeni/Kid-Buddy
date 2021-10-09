//
//  DataHandler.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/4/21.
//
import Foundation
import Firebase
import GeoFire


let DBReference = Database.database().reference()
let userReference = DBReference.child("users")
let childLocationReference = DBReference.child("childLocation")
let TrackedChildsReference = DBReference.child("TrackedChilds")
let MessagesReference = DBReference.child("Messages")

struct DataHandler{
    static let shared  = DataHandler()
    
    func fetchUserInfo(completion : @escaping (User) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}

        userReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            let userID = snapshot.key
            guard let userInfo = snapshot.value as? [String : Any] else {return}
            let user = User(uid: userID, dictionary: userInfo)
            completion(user)
        }
    }
    
    
    
    func fetchChildLocation(for childID : String, completion : @escaping (CLLocation?) -> Void){
        let geofire = GeoFire(firebaseRef: childLocationReference)
        childLocationReference.observe(.value) { (snapshot) in
            geofire.getLocationForKey(childID) { (location, error) in
                if error != nil {print(error!.localizedDescription) }
                guard let childLocation = location else {return}
                completion(childLocation)
            }
        }
    }
    
    func fetchChildInfo(completion : @escaping (Child , _ childID : String) -> Void)  {
        guard let uid = Auth.auth().currentUser?.uid else {return}

        TrackedChildsReference.child(uid).observe(.childAdded, with: { (snapshot) in
            guard let childInfo = snapshot.value as? [String : Any] else {return}
            let child = Child(ParentID: uid, ChildInfo: childInfo)
            let childID = snapshot.key
            completion(child,childID)
           })
        }
    
    
    func uploadMessageWithInfo(_ messageText : String , _ recipient : String)  {
        let sender = Auth.auth().currentUser?.uid
        let messageBody = messageText
        let recipient = recipient
        let timestamp = Int(Date().timeIntervalSince1970)
        let messsageInfo = ["sender" : sender!, "body"  : messageBody,"recipient" : recipient, "timestamp" : timestamp] as [String : Any]
        fetchUserInfo { (user) in
            if user.accountType == 0{
                MessagesReference.child(sender!).child(recipient).childByAutoId().updateChildValues(messsageInfo)
            }
            else if user.accountType == 1{
                MessagesReference.child(user.parentID).child(sender!).childByAutoId().updateChildValues(messsageInfo)
               }
             }
         }
    }
    
    
    
    
    

