//
//  DataHandler.swift
//  TracKids
//
//  Created by AHMED GAMAL  on 2/4/21.
import UIKit
import Firebase
import GeoFire
import CryptoKit

let DBReference = Database.database().reference()
let UserReference = DBReference.child("users")
let ChildLocationReference = DBReference.child("childLocation")
let TrackedChildsReference = DBReference.child("TrackedChilds")
let MessagesReference = DBReference.child("Messages")
let ObservedPlacesReference = DBReference.child("ObservedPlaces")
let HistoryReference = DBReference.child("LocationHistory")
let OTPReference = DBReference.child("OTPLinking")
let storage = Storage.storage()
var FetchedPlaces = [CLLocation]()
var placesIds = [String]()

struct DataHandler{
    static  let shared  = DataHandler()
    let deleteDataGroup = DispatchGroup()
    let semaphore = DispatchSemaphore(value: 0)
    func fetchUserInfo(completionHandler : @escaping (User) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        UserReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            let userID = snapshot.key
            guard let userInfo = snapshot.value as? [String : Any] else {return}
            let user = User(uid: userID, dictionary: userInfo)
            print("token of device \(String(describing: user.deviceID))")
            completionHandler(user)
        }
    }
    
    // MARK: - function to get  information of user's child
    func fetchChildAccount(with childId : String, completionHandler : @escaping (User) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        TrackedChildsReference.child(uid).child(childId).observeSingleEvent(of: .value) { snapshot in
            let childID = snapshot.key
            guard let childInfo = snapshot.value as? [String : Any] else {return}
            let child = User(uid: childID, dictionary: childInfo)
            completionHandler(child)
        }
    }
    
    // MARK: - function to get  List of user's childs.
    func fetchChildsInfo(for uid : String, completionHandler : @escaping (User ,  _ childID : String) -> Void)  {
        TrackedChildsReference.child(uid).observe(.childAdded, with: { (snapshot) in
            guard let childInfo = snapshot.value as? [String : Any] else {
                return}
            let childID = snapshot.key
            let child = User(uid: childID, dictionary: childInfo)
            completionHandler(child,childID)
        })
    }
    
    // MARK: - function to get  real time location of a specific child.
    func fetchChildLocation(for childID : String, completionHandler : @escaping (CLLocation?) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let geofire = GeoFire(firebaseRef: ChildLocationReference.child(uid))
        ChildLocationReference.child(uid).observe(.value) { (snapshot) in
            geofire.getLocationForKey(childID) { (location, error) in
                if error != nil {print("Debug: error \(String(describing: error!.localizedDescription))") }
                guard let childLocation = location else {return}
                completionHandler(childLocation)
            }
        }
    }
    
    
    // MARK: - function to get observed locations that set to a specific child.
    func fetchObservedPlaces(for childID : String, of ParentId : String, completionHandler : @escaping ([CLLocation]?, [String]) -> Void){
        FetchedPlaces = []
        placesIds = []
        let geofire = GeoFire(firebaseRef: ObservedPlacesReference.child(ParentId).child(childID))
        ObservedPlacesReference.child(ParentId).child(childID).observe(.childAdded) { (snapshot) in
            let key = snapshot.key
            placesIds.append(key)
            geofire.getLocationForKey(key) { (location, error) in
                if error != nil {print("Debug: error \(String(describing: error!.localizedDescription))") }
                guard let FetchedPlace = location else {return}
                FetchedPlaces.append(FetchedPlace)
                completionHandler(FetchedPlaces,placesIds)
            }
        }
    }
    
    // MARK: - function to upload observed location to firebase that set to a specific child.
    func uploadObservedPlace(_ location : CLLocation, addressTitle : String,for Child : String){
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let placeReference = ObservedPlacesReference.child(uid).child(Child)
        let key = addressTitle
        let geoFire = GeoFire(firebaseRef: placeReference)
        geoFire.setLocation(location, forKey: key )
    }
    
    // MARK: - function to upload Meessage Info to firebase specific user.
    func uploadMessageWithInfo(_ messageText : String , _ recipient : String, ImageURL : String? ,completionHandler : @escaping(() -> Void) )  {
        guard  let sender = Auth.auth().currentUser?.uid else{return}
        let messageBody = messageText
        let recipient = recipient
        let timestamp = Int(Date().timeIntervalSince1970)
        let fromDevice : String? = AppDelegate.DEVICEID
        let messsageInfo = ["sender" : sender,
                            "body"  : messageBody,
                            "recipient" : recipient,
                            "timestamp" : timestamp,
                            "fromDevice": fromDevice ?? "no device",
                            "imageURL" : ImageURL ?? ""] as [String : Any]
        self.fetchUserInfo { (user) in
            if user.accountType == 0 {
                MessagesReference.child(sender).child(recipient).childByAutoId().updateChildValues(messsageInfo) { error, ـ in
                    if error != nil {
                        print("Debug: error \(String(describing: error!.localizedDescription))")
                    }
                    else {
                        completionHandler()
                    }
                }
            }
            else if user.accountType == 1 {
                MessagesReference.child(user.parentID!).child(sender).childByAutoId().updateChildValues(messsageInfo) { error, ـ in
                    if error != nil {
                        print("Debug: error \(String(describing: error!.localizedDescription))")
                    }
                    else {
                        completionHandler()
                    }
                }
            }
        }
    }
    
    // MARK: - function to send Push Notification to a specific user.
    func sendPushNotification(to recipientToken : String, sender : String, body : String) {
        if let url = URL(string: AppDelegate.NOTIFICATION_URL) {
            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
            request.httpMethod = "POST"
            request.httpBody = "{\"to\":\"\(recipientToken)\",\"notification\":{\"title\":\"\(sender)\",\"body\":\"\(body)\",\"sound\":\"default\",\"mutable_content\":\"true\",\"content-available\":\"true\",\"badge\":\"1\"}}".data(using: .utf8)
            URLSession.shared.dataTask(with: request) { (_, urlresponse, error) in
                if error != nil {
                    print("error")
                } else {
                    print("Debug: sent notification and get response: \(String(describing: urlresponse))!.....")
                }
            }.resume()
        }
    }
    
    // MARK: - function to send Critical Alert Push Notification to a specific user.
    func sendCriticalAlert(to recipientToken : String, sender : String, body : String) {
        if let url = URL(string: AppDelegate.NOTIFICATION_URL) {
            var request = URLRequest(url: url)
            request.allHTTPHeaderFields = ["Content-Type":"application/json", "Authorization":"key=\(AppDelegate.SERVERKEY)"]
            request.httpMethod = "POST"
            request.httpBody =
            "{\"to\":\"\(recipientToken)\",\"notification\":{\"sound\":{\"critical\":\"1\",\"name\":\"criticalAlert.wav\",\"volume\":\"1\"}\"title\":\"\(sender)\",\"body\":\"\(body)\",\"badge\":\"1\",\"mutable_content\":\"true\",\"content_available\":\"true\"}}".data(using: .utf8)
            URLSession.shared.dataTask(with: request) { (_ , urlresponse, error) in
                if error != nil {
                    print("error")
                } else {
                    print("Debug: sent notification and get response: \(String(describing: urlresponse))!.....")
                }
            }.resume()
        }
    }
    
    // MARK: - function to fetch a device ID of a specific user from realtime database.
    func fetchDeviceID(for uid : String,  completionHandler : @escaping (String) -> Void) {
        UserReference.child(uid).observeSingleEvent(of: .value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else {return}
            let recipientDevice = dictionary["deviceID"] as! String
            let name = dictionary["name"] as! String
            print("Debug:  Device name is \(name)")
            print("Debug:  Device is \(recipientDevice)")
            completionHandler(recipientDevice)
        }
    }
    
    // MARK: - function to Remove user data from Database & Storage
    func deleteUserData(user currentUser: FirebaseAuth.User) {
        // Check if `currentUser.delete()` won't require re-authentication
        if let lastSignInDate = currentUser.metadata.lastSignInDate,
           lastSignInDate.minutes(from: Date()) >= -5 {
            deleteDataGroup.enter()
            let userId = currentUser.uid
            UserReference.child(userId).removeValue { error, _ in
                if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                self.deleteDataGroup.leave()
            }
            deleteDataGroup.enter()
            ChildLocationReference.child(userId).removeValue { error, _ in
                if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                self.deleteDataGroup.leave()
            }
            deleteDataGroup.enter()
            HistoryReference.child(userId).removeValue { error, _ in
                if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                self.deleteDataGroup.leave()
            }
            deleteDataGroup.enter()
            TrackedChildsReference.child(userId).removeValue { error, _ in
                if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                self.deleteDataGroup.leave()
            }
            
            deleteDataGroup.enter()
            ObservedPlacesReference.child(userId).removeValue { error, _ in
                if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                self.deleteDataGroup.leave()
            }
            
            deleteDataGroup.enter()
            MessagesReference.child(userId).removeValue { error, _ in
                if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                self.deleteDataGroup.leave()
            }
            //list and run over all files to delete each one independently
            deleteDataGroup.enter()
            let storageReference = storage.reference()
            let imageMessagesReference  = storageReference.child("Messages/\(String(describing: userId))")
            imageMessagesReference.listAll { list, error in
                if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                list.items.forEach({ file in
                    self.deleteDataGroup.enter()
                    file.delete { error in
                        if error != nil{print("Debug: error \(String(describing: error!.localizedDescription))")}
                        self.deleteDataGroup.leave()
                    }
                })
                self.deleteDataGroup.leave()
            }
        }
    }
    
    // MARK: - function to remove all child account data of a specific user from realtime database.
    func removeChild(withId childID : String){
        self.fetchChildAccount(with: childID) { child in
            guard  let parentId = Auth.auth().currentUser?.uid else{return}
            deleteDataGroup.enter()
            ChildLocationReference.child(parentId).child(childID).removeValue { error, _ in
                if let error = error {print(error)}
                self.deleteDataGroup.leave()
            }
            
            deleteDataGroup.enter()
            HistoryReference.child(parentId).child(childID).removeValue { error, _ in
                if let error = error { print(error) }
                self.deleteDataGroup.leave()
            }
            
            deleteDataGroup.enter()
            TrackedChildsReference.child(parentId).child(childID).removeValue { error, _ in
                if let error = error { print(error) }
                self.deleteDataGroup.leave()
            }
            deleteDataGroup.enter()
            ObservedPlacesReference.child(parentId).child(childID).removeValue { error, _ in
                if let error = error { print(error) }
                self.deleteDataGroup.leave()
            }
            deleteDataGroup.enter()
            MessagesReference.child(parentId).child(childID).removeValue { error, _ in
                if let error = error { print(error) }
                self.deleteDataGroup.leave()
            }
            //list and run over all files to delete each one independently.
            deleteDataGroup.enter()
            if let url = child.imageURL{
                let storageRef = storage.reference(forURL: url)
                storageRef.delete { error in
                    if let error = error {print("Debug: removing error \(error.localizedDescription)")}
                    else {
                        print("Debug: child account removed successfully")
                    }
                    self.deleteDataGroup.leave()
                }
            }
        }
    }
    
    // MARK: - function to change a specific user information and image.
    func updateChildInfo(forId childId : String, withImage newImage : UIImage, name: String, completionHandler : @escaping () -> Void){
        guard let parenId = Auth.auth().currentUser?.uid else {return}
        var imageReference = StorageReference()
        let storageReference = storage.reference()
        var imageURL = String()
        let userReference = UserReference.child(childId)
        DispatchQueue.global().async {
            //fetching child info to get name and parennt Id and get reference to profile image
            self.fetchChildAccount(with: childId) { child in
                let childName = child.name
                imageReference  = storageReference.child("ChildsPictures/\(parenId)/\(childName).jpg")
                self.semaphore.signal()
            }
            //delete profile image from storage
            self.semaphore.wait()
            imageReference.delete{ error in
                if error != nil{print("error in deleting\(String(describing: error?.localizedDescription))")}
                self.semaphore.signal()
            }
            
            //create reference to new child image and upload new image to storage
            self.semaphore.wait()
            if let imageData =  newImage.jpegData(compressionQuality: 0.3){
                let newImageReference  = storageReference.child("ChildsPictures/\(parenId)/\(name).jpg")
                newImageReference.putData(imageData, metadata: nil) { metaData, error in
                    if error != nil {print(error!.localizedDescription)}
                    //get new image url to update child info
                    newImageReference.downloadURL { (url, error) in
                        if error != nil {print(error!.localizedDescription)}
                        imageURL = url?.absoluteString ?? ""
                        self.semaphore.signal()
                    }
                }
            }
            //update child account with new child info
            self.semaphore.wait()
            userReference.updateChildValues(["imageURL" : imageURL, "name" : name]) { error, reference in
                if error != nil {print(error!.localizedDescription)}
                self.semaphore.signal()
            }
            //update tracked childs with new child info
            self.semaphore.wait()
            let trackedChildReference = TrackedChildsReference.child(parenId).child(childId)
            trackedChildReference.updateChildValues(["imageURL" : imageURL, "name" : name]) { error, reference in
                if error != nil {print(error!.localizedDescription)}
                completionHandler()
            }
        }
    }
}
