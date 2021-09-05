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
struct DataHandler{
    static let shared  = DataHandler()
    
    func fetchUserInfo(UId : String, completion : @escaping (User) -> Void) {
        
        userReference.child(UId).observeSingleEvent(of: .value) { (snapshot) in
            let userID = snapshot.key
            guard let userInfo = snapshot.value as? [String : Any] else {return}
            let user = User(uid: userID, dictionary: userInfo)
            completion(user)
        }
    }
    
    
    
    func fetchChildLocation(uid : String, completion : @escaping (CLLocation?) -> Void){
        
        let geofire = GeoFire(firebaseRef: childLocationReference)
        childLocationReference.observe(.value) { (snapshot) in
            let childUid = uid
            geofire.getLocationForKey(childUid) { (location, error) in
                if error != nil {print(error!.localizedDescription) }
                guard let childLocation = location else {return}
                completion(childLocation)
            }
        }
    }
    
    func fetchChildInfo(UId : String, completion : @escaping (Child) -> Void)  {
        TrackedChildsReference.child(UId).observe(.childAdded, with: { (snapshot) in
            guard let childInfo = snapshot.value as? [String : Any] else {return}
            let child = Child(ParentID: UId, ChildInfo: childInfo)
            completion(child)
           })
        }
    }
    
    
    
    
    

