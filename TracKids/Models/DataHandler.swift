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
let UserReference = DBReference.child("users")
let ChildLocationReference = DBReference.child("childLocation")
let TrackedChildsReference = DBReference.child("TrackedChilds")
let MessagesReference = DBReference.child("Messages")
let ObservedPlacesReference = DBReference.child("ObservedPlaces")
var FetchedPlaces = [CLLocation]()

struct DataHandler{
    static  let shared  = DataHandler()
    
    func fetchUserInfo(completion : @escaping (User) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}

        UserReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            let userID = snapshot.key
            guard let userInfo = snapshot.value as? [String : Any] else {return}
            let user = User(uid: userID, dictionary: userInfo)
            completion(user)
        }
    }
    
    func fetchChildLocation(for childID : String, completion : @escaping (CLLocation?) -> Void){
        let geofire = GeoFire(firebaseRef: ChildLocationReference)
        ChildLocationReference.observe(.value) { (snapshot) in
            print("Debug : \(String(describing: snapshot.value))")
            geofire.getLocationForKey(childID) { (location, error) in
                if error != nil {print(error!.localizedDescription) }
                guard let childLocation = location else {return}
                completion(childLocation)
            }
        }
    }
    
//    func fetchObservedPlaces(for childID : String, completion : @escaping ([CLLocation]?) -> Void){
//        let geofire = GeoFire(firebaseRef: ObservedPlacesReference.child(childID))
//
//        ObservedPlacesReference.child(childID).observe(.childAdded) { (snapShot) in
//            let key = snapShot.key
//            geofire.getLocationForKey(key) { (location, error) in
//                if error != nil {print(error!.localizedDescription) }
//                guard let FetchedPlace = location else {return}
//
//                FetchedPlaces.append(FetchedPlace)
//                completion(FetchedPlaces)
//                print("Debug count ddd :  \(String(describing: FetchedPlaces.last))")
//            }
//        }
//    }
    
    func fetchObservedPlaces(for childID : String, completion : @escaping ([CLLocation]?) -> Void){
        FetchedPlaces = []
        let geofire = GeoFire(firebaseRef: ObservedPlacesReference.child(childID))
        
        ObservedPlacesReference.child(childID).observe(.childAdded) { (snapShot) in
            
            let key = snapShot.key
            geofire.getLocationForKey(key) { (location, error) in
                if error != nil {print(error!.localizedDescription) }
                guard let FetchedPlace = location else {return}
                
                FetchedPlaces.append(FetchedPlace)
                completion(FetchedPlaces)
                print("Debug count ddd :  \(String(describing: FetchedPlaces.last))")
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
    
   
    
    func uploadObservedPlace(_ location : CLLocation, for Child : String){
        let placeReference = ObservedPlacesReference.child(Child)
        let key = ObservedPlacesReference.childByAutoId().key
       
        let geoFire = GeoFire(firebaseRef: placeReference)
        geoFire.setLocation(location, forKey: key ?? "no key")
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
    
    
    
    
    

